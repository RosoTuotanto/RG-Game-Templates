"""Renders the SVG files in this folder into the PNG files of the core and the templates."""

import argparse
import json
import os
import re
import selectors
import shutil
import signal
import subprocess
import sys
import tempfile
import time
import xml.etree.ElementTree as ElementTree
from pathlib import Path

from PIL import Image

IMAGES_DIR = Path(__file__).resolve().parent
SRC_DIR = IMAGES_DIR.parent
REPO_DIR = SRC_DIR.parent

CONFIG = json.loads((IMAGES_DIR / "config.json").read_text(encoding="utf-8"))
LENGTH = re.compile(r"^\s*([0-9]*\.?[0-9]+)\s*(px)?\s*$")
LOCK_FILE = Path(tempfile.gettempdir()) / "rg-game-templates-build-images.lock"


class BuildError(Exception):
	pass


def target_png(relative: Path) -> Path:
	"""Returns the PNG a source builds: the same path inside the game folder of the core or of the template the first folder names."""
	layer = relative.parts[0]
	game = SRC_DIR / "core" / "game" if layer == "core" else SRC_DIR / "templates" / layer / "game"

	return game.joinpath(*relative.parts[1:]).with_suffix(".png")


def select_sources(paths: list[str]) -> list[Path]:
	every = sorted(svg for svg in IMAGES_DIR.rglob("*.svg") if len(svg.relative_to(IMAGES_DIR).parts) > 1)

	if not paths:
		return every

	chosen = []

	for text in paths:
		candidate = Path(text).resolve()

		if IMAGES_DIR not in candidate.parents:
			candidate = (IMAGES_DIR / text).resolve()

		matched = [svg for svg in every if svg == candidate or candidate in svg.parents]

		if not matched:
			sys.exit(f"{text} is not an SVG file or a folder with SVG files in {IMAGES_DIR}")

		chosen.extend(svg for svg in matched if svg not in chosen)

	return chosen


def svg_size(svg: Path) -> tuple[int, int]:
	try:
		root = ElementTree.parse(svg).getroot()
	except (ElementTree.ParseError, OSError) as error:
		raise BuildError(f"cannot read the file: {error}")

	sizes = []

	for name, view_box_index in (("width", 2), ("height", 3)):
		value = root.get(name)

		if value is None:
			view_box = (root.get("viewBox") or "").replace(",", " ").split()

			if len(view_box) != 4:
				raise BuildError(f"the svg element has no {name} and no viewBox")

			size = float(view_box[view_box_index])
		else:
			match = LENGTH.match(value)

			if match is None:
				raise BuildError(f"{name}={value!r} must be a plain number or px")

			size = float(match.group(1))

		if size <= 0 or abs(size - round(size)) > 1e-6:
			raise BuildError(f"{name} {size:g} must be a positive whole number of pixels")

		sizes.append(round(size))

	return sizes[0], sizes[1]


def read_stat(pid: int) -> tuple[int, int] | None:
	"""Returns (parent pid, start time) from /proc, or None when the process is gone."""
	try:
		text = Path(f"/proc/{pid}/stat").read_text()
	except (FileNotFoundError, ProcessLookupError):
		return None

	# The command name may hold spaces or parentheses, so the fields start after the last ')'.
	fields = text[text.rindex(")") + 2:].split()
	return int(fields[1]), int(fields[19])


def rss_kb(pid: int) -> int:
	try:
		lines = Path(f"/proc/{pid}/status").read_text().splitlines()
	except (FileNotFoundError, ProcessLookupError):
		return 0

	for line in lines:
		if line.startswith("VmRSS:"):
			return int(line.split()[1])

	return 0


def process_tree(root: int) -> dict[int, int]:
	"""Maps every live descendant of root, root included, to its start time."""
	children: dict[int, list[int]] = {}
	starts: dict[int, int] = {}

	for entry in os.listdir("/proc"):
		if not entry.isdigit():
			continue

		stat = read_stat(int(entry))

		if stat is None:
			continue

		children.setdefault(stat[0], []).append(int(entry))
		starts[int(entry)] = stat[1]

	tree = {}
	pending = [root]

	while pending:
		pid = pending.pop()

		if pid in starts:
			tree[pid] = starts[pid]
			pending.extend(children.get(pid, []))

	return tree


def kill_seen(root: int, seen: dict[int, int]) -> None:
	"""Kills the process group and every process seen in the tree that is still the same process, because Chromium runs in its own session."""
	try:
		os.killpg(root, signal.SIGKILL)
	except ProcessLookupError:
		# The group has already exited; processes in other sessions are handled below.
		pass

	for pid, start in seen.items():
		stat = read_stat(pid)

		if stat is None or stat[1] != start:
			continue

		try:
			os.kill(pid, signal.SIGKILL)
		except ProcessLookupError:
			# Killing a parent can take its children with it.
			continue


def run_bounded(command: list[str], environment: dict) -> tuple[str, int | None, str]:
	"""Runs a child under a time limit and a memory cap over its whole process tree, and returns its status, exit code and the end of its output."""
	bounds = CONFIG["bounds"]
	cap_kb = int(bounds["memory_cap_mb"]) * 1024
	keep = int(bounds["output_cap_bytes"])
	poll = float(bounds["poll_seconds"])

	process = subprocess.Popen(command, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, env=environment, start_new_session=True)
	deadline = time.monotonic() + float(bounds["timeout_seconds"])
	output = b""
	seen: dict[int, int] = {}
	status = "ok"
	stream_open = True

	try:
		with selectors.DefaultSelector() as selector:
			selector.register(process.stdout, selectors.EVENT_READ)

			while stream_open or process.poll() is None:
				if time.monotonic() > deadline:
					status = "timeout"
					break

				tree = process_tree(process.pid)
				seen.update(tree)

				if sum(rss_kb(pid) for pid in tree) > cap_kb:
					status = "memory"
					break

				if not stream_open:
					time.sleep(poll)
					continue

				# Reading the pipe on every poll keeps the child from blocking on a full pipe.
				for key, _ in selector.select(poll):
					chunk = os.read(key.fd, 65536)

					if chunk:
						output = (output + chunk)[-keep:]
					else:
						selector.unregister(key.fileobj)
						stream_open = False
	finally:
		kill_seen(process.pid, seen)
		process.wait()
		process.stdout.close()

	returncode = process.returncode if status == "ok" else None
	return status, returncode, output.decode(errors="replace")


def node_environment() -> dict:
	"""Adds the global npm folder to NODE_PATH, so Node finds a globally installed Playwright."""
	environment = dict(os.environ)

	if environment.get("NODE_PATH"):
		return environment

	node = shutil.which("node")

	if node is not None:
		global_root = Path(node).resolve().parent.parent / "lib" / "node_modules"

		if (global_root / "playwright").is_dir():
			environment["NODE_PATH"] = str(global_root)

	return environment


def render(svg: Path, job_dir: Path, environment: dict) -> Image.Image:
	width, height = svg_size(svg)
	supersample = int(CONFIG["render"]["supersample"])
	big_size = (width * supersample, height * supersample)
	max_side = int(CONFIG["render"]["max_supersampled_side"])

	if max(big_size) > max_side:
		raise BuildError(f"{big_size[0]}x{big_size[1]} at {supersample}x passes the {max_side} px limit (max_supersampled_side in config.json)")

	big_png = job_dir / "render.png"
	job_file = job_dir / "job.json"

	job = {
		"svg": str(svg),
		"output": str(big_png),
		"width": width,
		"height": height,
		"deviceScale": supersample,
	}

	job_file.write_text(json.dumps(job), encoding="utf-8")
	big_png.unlink(missing_ok=True)

	status, returncode, output = run_bounded(["node", str(IMAGES_DIR / "render_svg.cjs"), str(job_file)], environment)

	if status == "timeout":
		raise BuildError(f"the render did not finish within {CONFIG['bounds']['timeout_seconds']} s and was stopped")

	if status == "memory":
		raise BuildError(f"the render passed the {CONFIG['bounds']['memory_cap_mb']} MB memory cap and was stopped")

	if returncode != 0 or not big_png.is_file():
		raise BuildError(f"the render failed (exit {returncode}):\n{output.strip()}")

	with Image.open(big_png) as big:
		if big.size != big_size:
			raise BuildError(f"Chromium returned {big.size[0]}x{big.size[1]}, expected {big_size[0]}x{big_size[1]}")

		# Averaging in premultiplied alpha keeps the colour of transparent pixels out of the edges.
		return big.convert("RGBA").convert("RGBa").resize((width, height), Image.Resampling.BOX).convert("RGBA")


def extruded(tile: Image.Image, extrude: int) -> Image.Image:
	"""Returns the tile with its outermost pixel rows and columns repeated extrude times outward."""
	width, height = tile.size
	padded = Image.new("RGBA", (width + 2 * extrude, height + 2 * extrude))
	padded.paste(tile, (extrude, extrude))

	padded.paste(tile.crop((0, 0, 1, height)).resize((extrude, height), Image.Resampling.NEAREST), (0, extrude))
	padded.paste(tile.crop((width - 1, 0, width, height)).resize((extrude, height), Image.Resampling.NEAREST), (width + extrude, extrude))

	full_width = padded.width
	padded.paste(padded.crop((0, extrude, full_width, extrude + 1)).resize((full_width, extrude), Image.Resampling.NEAREST), (0, 0))
	padded.paste(padded.crop((0, height + extrude - 1, full_width, height + extrude)).resize((full_width, extrude), Image.Resampling.NEAREST), (0, height + extrude))

	return padded


def pack_tileset(grid: Image.Image, tileset: dict) -> Image.Image:
	"""Cuts a tight grid of tiles apart and lays the tiles out with extruded edges: a margin of extrude and a spacing of twice that."""
	tile_width = int(tileset["tile_width"])
	tile_height = int(tileset["tile_height"])
	extrude = int(tileset["extrude"])

	if grid.width % tile_width or grid.height % tile_height:
		raise BuildError(f"the image is {grid.width}x{grid.height}, not a whole number of {tile_width}x{tile_height} tiles")

	columns = grid.width // tile_width
	rows = grid.height // tile_height
	step_x = tile_width + 2 * extrude
	step_y = tile_height + 2 * extrude
	sheet = Image.new("RGBA", (columns * step_x, rows * step_y))

	for row in range(rows):
		for column in range(columns):
			left = column * tile_width
			top = row * tile_height
			tile = grid.crop((left, top, left + tile_width, top + tile_height))
			sheet.paste(extruded(tile, extrude), (column * step_x, row * step_y))

	return sheet


def take_lock() -> None:
	"""Stops a second run while one is going; a lock whose process no longer exists is taken over."""
	own = LOCK_FILE.with_name(f"{LOCK_FILE.name}.{os.getpid()}")
	own.write_text(str(os.getpid()))

	try:
		while True:
			try:
				os.link(own, LOCK_FILE)
				return
			except FileExistsError:
				holder = LOCK_FILE.read_text().strip()

				if Path(f"/proc/{holder}").is_dir():
					sys.exit(f"build_images.py is already running (process {holder}).")

				LOCK_FILE.unlink(missing_ok=True)
	finally:
		own.unlink()


def main() -> None:
	parser = argparse.ArgumentParser(description=__doc__)
	parser.add_argument("paths", nargs="*", help="folders or SVG files in this folder to build, such as top-down or core/assets/images/template/ui/slider.svg (default: every SVG file)")
	arguments = parser.parse_args()

	if not Path("/proc").is_dir():
		sys.exit("build_images.py runs on Linux only: it reads /proc to keep the memory use of a render under its cap.")

	sources = select_sources(arguments.paths)
	environment = node_environment()
	failed = []

	take_lock()
	job_dir = Path(tempfile.mkdtemp(prefix="rg-images-"))

	try:
		for svg in sources:
			relative = svg.relative_to(IMAGES_DIR)
			target = target_png(relative)

			try:
				image = render(svg, job_dir, environment)
				tileset = CONFIG["tilesets"].get(relative.as_posix())

				if tileset is not None:
					image = pack_tileset(image, tileset)

				if relative.as_posix() in CONFIG["opaque"]:
					image = image.convert("RGB")
			except BuildError as error:
				failed.append(relative.as_posix())
				print(f"FAILED {relative.as_posix()}: {error}", file=sys.stderr)
				continue

			target.parent.mkdir(parents=True, exist_ok=True)
			image.save(target)
			print(f"{target.relative_to(REPO_DIR).as_posix()} {image.width}x{image.height}")
	finally:
		shutil.rmtree(job_dir)
		LOCK_FILE.unlink(missing_ok=True)

	print(f"{len(sources) - len(failed)} of {len(sources)} images built.")

	if failed:
		sys.exit(f"FAILED: {', '.join(failed)}")


if __name__ == "__main__":
	main()
