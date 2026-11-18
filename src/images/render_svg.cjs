"use strict";

// Screenshots one SVG file in headless Chromium for build_images.py, at the job's device scale with a transparent background.

const fs = require("fs");
const { pathToFileURL } = require("url");
const { chromium } = require("playwright");

async function main() {
	const job = JSON.parse(fs.readFileSync(process.argv[2], "utf8"));
	const problems = [];

	const browser = await chromium.launch({ headless: true });

	try {
		const context = await browser.newContext({
			viewport: { width: job.width, height: job.height },
			deviceScaleFactor: job.deviceScale
		});

		const page = await context.newPage();

		page.on("pageerror", (error) => problems.push(`page error: ${error.message}`));
		page.on("requestfailed", (request) => problems.push(`missing resource: ${request.url()}`));

		await page.goto(pathToFileURL(job.svg).href, { waitUntil: "load" });
		await page.evaluate(() => document.fonts.ready.then(() => true));

		const rootName = await page.evaluate(() => document.documentElement.localName);

		if (rootName !== "svg") {
			problems.push(`Chromium did not load the file as SVG (root element: ${rootName})`);
		}

		if (problems.length > 0) {
			throw new Error(problems.join("\n"));
		}

		await page.screenshot({ path: job.output, omitBackground: true });
	} finally {
		await browser.close();
	}
}

main().catch((error) => {
	console.error(error.message);
	process.exit(1);
});
