/**
 * Module for handling redirection from the old Wilde trials
 * site to the flattened static version. The Wilde site had the following paths:
 *
 * view.html?f=flt_3387
 * city-details.html?city=Akaroa
 * date-details.html?date=1895-04-02
 * language-details.html?language=fr
 * newspaper-details.html?publisher=a_li_1
 * region-details.html?region=Bahamas
 * source-details.html?source=American%20Periodicals&type=database
 *
 * @author Joey Takeda <takeda@sfu.ca>
 * November 2024
 */

// Query values from from the window's URL

const { pathname, search, origin } = window.location;
const docId = document.querySelector("html").id;
const params = new URLSearchParams(search);

/**
 * Set of replacements:
 *  * the key is the page name
 *  * param is the parameter to use
 *  * replace is a function for replacement
 */
const replacements = {
  view: {
    param: "f",
    replace: (f) => {
      return `${f}`;
    },
  },
  "city-details": {
    param: "city",
    replace: (city) => {
      return `city-${city}`;
    },
  },
  "date-details": {
    param: "date",
    replace: (date) => {
      return `date-${date}`;
    },
  },
  "language-details": {
    param: "language",
    replace: (language) => {
      return `language-${language}`;
    },
  },
  "newspaper-details": {
    param: "publisher",
    replace: (publisher) => {
      return `newspaper-${publisher}`;
    },
  },
  "region-details": {
    param: "region",
    replace: (region) => {
      return `region-${region}`;
    },
  },
  "source-details": {
    param: "source",
    replace: (source) => {
      // Per MDN
      const decoded = decodeURIComponent(source.replace(/\+/g, " "));
      const normalized = decoded
        .trim()
        .replace(/\s+/gi, "_")
        .replace(/[^\w-]+/gi, "");
      return `source-${normalized}`;
    },
  },
};

const goHome = () => {
  console.log("Cannot resolve redirect; returning home");
  return (window.location.href = origin);
};

const redirect = async () => {
  if (!replacements[docId]) {
    goHome();
  }
  // Get all of the site ids
  const allIds = await (await fetch("./resources/sitemap.json")).json();
  const { param, replace } = replacements[docId];
  const value = params.get(param) ?? "NULL";
  const newBase = replace(value);
  const exists = allIds.hasOwnProperty(newBase);
  if (exists) {
    window.location.href = `${origin}/${newBase}.html`;
  } else {
    goHome();
  }
};

window.addEventListener("DOMContentLoaded", redirect);
