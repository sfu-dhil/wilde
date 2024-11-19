import { default as lev } from "js-levenshtein";
import * as fs from "node:fs/promises";
import * as path from "node:path";
import { JSDOM } from "jsdom";
import * as parse5 from "parse5";

const reportsPath = "../../wilde-reports/";

const allFiles = await fs.readdir(reportsPath, {
  recursive: true,
});

const reportPaths = allFiles
  .filter((path) => /\.xml$/gi.test(path))
  .map((f) => path.join(reportsPath, f));

const reports = await Promise.all(
  reportPaths.map((path) => {
    return new Promise(async (resolve, reject) => {
      try {
        const file = await fs.readFile(path, {
          encoding: "utf8",
        });
        const document = JSDOM.fragment(file);
        return resolve(document);
      } catch (e) {
        return reject(e);
      }
    });
  })
);

const englishReports = [];

for (const report of reports) {
  if (englishReports.length === 10) {
    break;
  }
  if (report.querySelector(`meta[name='dc.language'][content='en']`)) {
    englishReports.push(report);
  }
}

const paragraphs = englishReports.flatMap((report) => {
  return [...report.querySelectorAll("p:not(.heading)")]
    .map((p) => p.textContent.trim())
    .filter((t) => t.length > 0);
});

let manyParagraphs = [];
for (let i = 0; i < 10000; i++) {
  manyParagraphs = manyParagraphs.concat(paragraphs);
}

comp(manyParagraphs);

function comp(array) {
  array.forEach((p, idx) => {
    array.splice(idx + 1).forEach((p2, idx) => {
      const comp = lev(p, p2);
      console.log(comp);
    });
  });
}
