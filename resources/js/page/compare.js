const urlParams = new URLSearchParams(window.location.search);
const a = urlParams.get("a");
const b = urlParams.get("b");
const JSON_PATH = `_data/`;

document.addEventListener("DOMContentLoaded", async () => {
  if (document.querySelector(".compare-content")) {
    if (!a || !b) {
      console.log(`Both a and b need to be defined`);
      return;
    }
    await compare();
  }
});

function getSortedParaIds(doc) {
  return Object.keys(doc)
    .filter((k) => k.startsWith(doc["id"]))
    .sort((a, b) => {
      return parseInt(a.split("_").pop()) - parseInt(b.split("_").pop());
    });
}

function formatPercent(float) {
  const percent = float * 100;
  return `${percent.toLocaleString(undefined, {
    minimumFractionDigits: 0,
    maximumFractionDigits: 1,
  })}%`;
}

function updateBreadcrumb(doc) {
  const breadcrumb = document.querySelector(".breadcrumb");
  const newItems = [];
  newItems.push(
    `<a href="newspaper_${doc["dc.publisher.id"]}.html">${doc["dc.publisher"]}</a>`
  );
  newItems.push(`<a href="${doc.id}.html">
    ${new Intl.DateTimeFormat("en-US", {
      day: "numeric",
      year: "numeric",
      month: "long",
      timeZone: "UTC",
    }).format(new Date(doc["dc.date"]))}
    </a>`);
  newItems.push(document.querySelector(".page-header > h1").innerText);
  const items = newItems
    .map((value, idx) => {
      const isLast = idx === newItems.length - 1;
      return `<li class="breadcrumb-item${
        isLast ? ' active" aria-current="page"' : '"'
      }>
      ${value}
      </li>`;
    })
    .join("");
  breadcrumb.insertAdjacentHTML("beforeend", items);
}

async function compare() {
  const docA = await (await fetch(`${JSON_PATH}${a}.json`)).json();
  const docB = await (await fetch(`${JSON_PATH}${b}.json`)).json();
  updateBreadcrumb(docA);
  const compareTable = document.querySelector(".compare-content");
  compareTable.querySelector(
    ".compare-a"
  ).innerHTML = `<a href="${a}.html">${docA.title}</a>`;
  compareTable.querySelector(
    ".compare-b"
  ).innerHTML = `<a href="${b}.html">${docB.title}</a>`;
  if (compareTable.classList.contains("compare-paragraphs")) {
    compareParagraphs();
  } else {
    compareDocuments();
  }

  function compareDocuments() {
    const idem = (a) => {
      return a;
    };
    const buildContent = (doc, cb = idem) => {
      return getSortedParaIds(doc)
        .map((k) => `<p>${cb(doc[k])}</p>`)
        .join("");
    };
    const docMatch = docA["doc-similarity"][b];
    document
      .querySelector("#col3 h3")
      .insertAdjacentHTML(
        "beforeend",
        `<br/><span>${
          docMatch
            ? `Match: ${formatPercent(docMatch.percentage)}`
            : "Not significantly similar"
        }</span>`
      );
    const diff = htmldiff(
      buildContent(docA, normalize),
      buildContent(docB, normalize)
    );
    document.querySelector("#doc_a").innerHTML = buildContent(docA);
    document.querySelector("#doc_b").innerHTML = buildContent(docB);
    document.querySelector("#diff").innerHTML = diff;
  }

  function compareParagraphs() {
    const dmp = new diff_match_patch();
    const allParaIds = getSortedParaIds(docA);
    for (const paraId of allParaIds) {
      const content = docA[paraId];
      const similarParas = docA["paragraph-similarity"][paraId] || {};
      const matches = Object.values(similarParas).filter(
        ({ document }) => document === b
      );
      const bestMatch = matches.sort((b1, b2) => {
        return b1.similarity - b2.similarity;
      })[0];
      let bContent = "—";
      let dContent = "<em>No similar paragraph</em>";
      if (bestMatch) {
        console.log(bestMatch);
        bContent = docB[bestMatch.paragraph];
        const diff = dmp.diff_main(normalize(content), normalize(bContent));
        dmp.diff_cleanupSemantic(diff);
        dContent = `<p>${htmlize(diff)}</p>`;
        console.log(bestMatch);
        dContent += `<em>Match ${formatPercent(bestMatch.similarity)}</em>`;
      }

      const row = `<div class="row paragraph-compare">
         <div class="col-sm-4 paragraph-a">
             <div class='content'><p>${content}</p></div>
        </div>
        <div class="col-sm-4 paragraph-b">
             <div class='content'><p>${bContent}</p></div>
        </div>
        <div class="col-sm-4 paragraph-d" data-caption="Difference">
            <div class="content">
                ${dContent}
            </div>
        </div>
    </div>`;
      compareTable.insertAdjacentHTML("beforeend", row);
    }
  }
}

function normalize(string) {
  var lower = string.toLowerCase().normalize("NFC");
  var lbs = lower.replace(/(\r\n|\n|\r)/gm, " ");
  var clean = lbs.replace(/\s+/g, " ");
  return clean;
}

function htmlize(diffs) {
  var html = [];
  var pattern_amp = /&amp;/g;
  var pattern_lt = /&lt;/g;
  var pattern_gt = /&gt;/g;
  var pattern_para = /\n/g;
  console.log(diffs);
  for (var x = 0; x < diffs.length; x++) {
    var op = diffs[x][0];
    // Operation (insert, delete, equal)
    var text = diffs[x][1];
    switch (op) {
      case DIFF_INSERT:
        html[x] = "<ins>" + text + "</ins>";
        break;
      case DIFF_DELETE:
        html[x] = "<del>" + text + "</del>";
        break;
      case DIFF_EQUAL:
        html[x] = "<span>" + text + "</span>";
        break;
    }
  }
  return html.join("");
}

// (function ($) {
//    window.addEventListener('onDOMReady', init);
//
//    async function init(){
// Get the first document
// Get the second document
// Shove the document into the structure
// And then run the comparison

//    }
//
//document.addEventListener('DOMContentLoaded', () => {
//  const dmp = new diff_match_patch();
//
//  document.querySelectorAll('div.paragraph-compare').forEach((element) => {
//    const contentA = element.querySelector('.paragraph-a .content');
//    const contentB = element.querySelector('.paragraph-b .content');
//    const displayElement = element.querySelector('.paragraph-d');
//
//    const textA = normalize(contentA.textContent);
//    const textB = normalize(contentB.textContent);
//
//    if (!textB) {
//      displayElement.innerHTML = '<em>No similar paragraph</em>';
//    } else {
//      const diff = dmp.diff_main(textA, textB);
//      dmp.diff_cleanupSemantic(diff);
//
//      const diffHtml = htmlize(diff);
//      displayElement.innerHTML = `<p>${diffHtml}</p>`;
//
//      const matchScore = element.dataset.score;
//      if (matchScore && matchScore !== '%') {
//        displayElement.insertAdjacentHTML('beforeend', `<em>Match: ${matchScore}</em>`);
//      } else {
//        displayElement.insertAdjacentHTML('beforeend', '<em>Too short to calculate match</em>');
//      }
//    }
//  });
//});

//   $(document).ready(function () {
//     var dmp = new diff_match_patch();
//     $("div.paragraph-compare").each(function () {
//       var $this = $(this);
//       var a = normalize($this.find(".paragraph-a .content").text());
//       var b = normalize($this.find(".paragraph-b .content").text());
//       var $d = $this.find(".paragraph-d");

//       if (!b) {
//         $d.html("<em>No similar paragraph</em>");
//       } else {
//         var diff = dmp.diff_main(a, b);
//         dmp.diff_cleanupSemantic(diff);
//         var html = htmlize(diff);
//         $d.html("<p>" + html + "</p>");
//         if ($this.data("score") !== "%") {
//           $d.append("<em>Match: " + $this.data("score") + "</em>");
//         } else {
//           $d.append("<em>Too short to calculate match</em>");
//         }
//       }
//     });
//   });
// })(jQuery);
