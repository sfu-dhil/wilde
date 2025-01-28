"use strict";

/**
 * Subclass of staticSearch (based on implementation for LOI) that provides additional
 * functionality for the LiM project.  In particular, we override some of the trickle
 * down behaviour slightly in order to provide a read-out of all filter values for a
 * search result.
 * @external "StaticSearch"
 * @see {@link https://endings.uvic.ca/staticSearch/docs/index.html}
 * @extends StaticSearch
 *
 */
class WildeSearch extends StaticSearch {
  /**
   *
   * @description Create a StaticSearch instance with additional properties for
   * rendering filter values
   *
   */
  constructor() {
    super();
    // Flag to set whether we want to render the filter values (we don't for the global search)
    // Flag for whether or not the made has been made; if we don't want to or there aren't
    // any filters, then we say it's already made; otherwise, we say it isn't
    this.docsToFilterMapMade = false;
    // Set up the filter map
    this.docsToFilterMap = new Map();
    this.allFilterNames = new Set();
    this.exportButton = document.querySelector("#export");
    this.exportButton.addEventListener("click", this.exportResults.bind(this));
  }

  /**
   * Getter for all of the fieldsets
   * @returns {NodeList} All fieldsets for  staticSearch.
   */
  get fieldsets() {
    return document.querySelectorAll("fieldset");
  }

  /**
   * @function retrieveAllFilters
   * @returns {Promise}
   * @description Async function triggered by a search that  downloads all of the
   * filter files if they hadn't been downloaded already so that
   * LoiStaticSearch can render the filter values. It compiles them all and then sends them
   * to jsonRetrieved.
   */
  retrieveAllFilters() {
    let self = this;
    return new Promise((resolve, reject) => {
      try {
        if (self.allJsonRetrieved && self.docsToFilterMapMade) {
          resolve(true);
          return;
        }

        let idsToRetrieve = [];

        // Go through the fieldsets and add the id for these (note that
        // does not include boolean filters
        [...self.fieldsets, ...self.boolFilterSelects].forEach((el) => {
          if (el.hasAttribute("id")) {
            idsToRetrieve.push(el.getAttribute("id"));
          }
        });

        // Make sure all of the ids we want to retrieve haven't already been trickled in
        idsToRetrieve = idsToRetrieve.filter(
          (id) => !this.mapJsonRetrieved.has(id)
        );

        // Now create a set of promises to fetch them, and to retrieve
        // them using the pre-build json to retrieve function
        let filtersToRetrieve = idsToRetrieve.map((id) => {
          let path = `${this.jsonDirectory}/filters/${id}${this.versionString}.json`;
          return fetch(path, this.fetchHeaders)
            .then((response) => {
              return response.json();
            })
            .then((json) => {
              self.jsonRetrieved(json, path);
            });
        });
        Promise.all(filtersToRetrieve).then((results) => {
          console.log("All filters retrieved.");
          self.docsToFilterMapMade = true;
          resolve(true);
        });
      } catch (e) {
        console.log("ERROR: " + e);
        reject(e);
      }
    });
  }

  parseUrlQueryString(popping = false) {
    if (popping) {
      return;
    }
    super.parseUrlQueryString(popping);
  }

  /**
   * @description Adds an additional step to the JSON retrieval process that
   * puts each retrieved filter JSON into the filter caption map.
   * @augments external:"StaticSearch".jsonRetrieved
   */
  jsonRetrieved(json, path) {
    // If we're matching a filter, make sure
    // to add it to the filter map
    if (path.match(/\/filters\//)) {
      this.processFiltersForCaptions(json);
    }
    // Call the parent function
    super.jsonRetrieved(json, path);
  }

  /**
   * @description Ensures that all filters have been retrieved before populating
   * the rest of the indexes.
   * @augments external:"StaticSearch".populateIndexes
   */
  populateIndexes() {
    // We override populate indexes to make sure we retrieve all the filters
    // if a search is triggered from the get go
    this.retrieveAllFilters().then((_) => {
      super.populateIndexes();
    });
  }

  exportResults(_e) {
    const self = this;
    const { mapDocs, titles } = this.resultSet;
    const results = [...mapDocs.values()].map(({ docUri, contexts, score }) => {
      const result = {};
      const id = docUri.split(".")[0];
      const title = titles.get(docUri)[0];
      const filters = self.docsToFilterMap.get(docUri);
      result["ID"] = id;
      result["Title"] = title;
      result["Score"] = score;
      self.allFilterNames.forEach((name) => {
        result[name] = filters[name][0] || null;
      });
      result["Result Count"] = contexts.length;
      result["Result"] = contexts
        .map(({ context }) => {
          return context.replaceAll(/<[^>]+>/gi, "");
        })
        .join(" || ");
      return result;
    });
    const csv = this.makeCSV(results);
    const _link = document.createElement("a");
    const blob = new Blob([csv], { type: "text/csv" });
    const url = window.URL.createObjectURL(blob);
    _link.style.display = "none";
    _link.href = url;
    _link.download = `wilde-search_${Math.round(+new Date() / 1000)}.csv`;
    document.body.appendChild(_link);
    _link.click();
    document.body.removeChild(_link);
    window.URL.revokeObjectURL(url);
  }
  //const replacer = (key, value) => value === null ? '' : value // specify how you want to handle null values here
  makeCSV(results) {
    const replacer = (_key, value) => {
      if (value === null) {
        return "";
      }
      if (_key === "Date") {
        return value;
      }
      if (/^[\d\.]+$/gi.test(value) && !Number.isNaN(parseFloat(value))) {
        return parseFloat(value);
      }
      return value;
    };
    const header = Object.keys(results[0]);
    const rows = [];
    rows.push(header.join(","));
    results.forEach((result) => {
      const row = header.map((fieldName) => {
        return JSON.stringify(result[fieldName], replacer);
      });
      rows.push(row);
    });
    const csv = rows.join("\r\n");
    return csv;
  }

  // /**
  //  * @description Overrides the phrase to regex method to allow for case-insensitive phrasal
  //  * searching
  //  * @param str {string} The phrasal string to process
  //  * @augments external:"StaticSearch".phraseToRegex
  //  */
  // phraseToRegex(str) {
  //   try {
  //     let re = StaticSearch.prototype.phraseToRegex(str);
  //     let source = re.source;
  //     return new RegExp(source, "i");
  //   } catch (e) {
  //     console.log("ERROR: Cannot construct new regex from " + str);
  //   }
  // }

  /**
   * @function processFiltersForCaption
   * @description Processes each filter object, inverting it so that each
   * document has a set of properties describing its filter values.
   * @param {Object} filter: The JSON filter to process.
   * @returns {boolean} true if successful, false otherwise.
   */
  processFiltersForCaptions(filter) {
    const self = this;

    /**
     * Retrieve the property value from the docsToFilterMap,
     * creating an entry if it doesn't already exist.
     * @param {String} doc: The document URI to use as a key
     * @returns {Array} The array in the docsToFilterMap to use for the documents
     */
    const getIndexVal = (doc) => {
      if (!this.docsToFilterMap.has(doc)) {
        this.docsToFilterMap.set(doc, {});
      }
      let docVal = this.docsToFilterMap.get(doc);
      if (!docVal.hasOwnProperty(name)) {
        docVal[name] = [];
      }
      return docVal[name];
    };

    /**
     * Set of methods for processing the different types of filter values, organized
     * by filter type.
     * @type {Object}
     */
    const methods = {
      /**
       * Function to process desc filters, which are structured by
       * subcategories with documents
       */
      desc: function () {
        for (const fid in filter) {
          if (typeof filter[fid] === "object") {
            let obj = filter[fid];
            let name = obj["name"];
            let docs = obj["docs"] || [];
            for (const doc of docs) {
              let indexVal = getIndexVal(doc);
              indexVal.push(name);
            }
          }
        }
      },

      /**
       * Function to handle num filters, which map documents to values.
       */
      num: function () {
        let docs = filter.docs;
        for (const doc in docs) {
          let indexVal = getIndexVal(doc);
          docs[doc].forEach((val) => {
            indexVal.push(val);
          });
        }
      },

      /**
       * Function to handle date filters, which map documents to values.
       *
       */
      date: function () {
        let docs = filter.docs;
        for (const doc in docs) {
          let indexVal = getIndexVal(doc);
          docs[doc].forEach((val) => {
            indexVal.push(val.trim());
          });
        }
      },

      /**
       * Function to handle boolean filters, which only have two keys (true or false).
       * Here we only care about ones that are true
       */
      bool: function () {
        for (const fid in filter) {
          if (typeof filter[fid] === "object") {
            let obj = filter[fid];
            let value = obj["value"];
            let docs = obj["docs"] || [];
            if (value === "true") {
              docs.forEach(getIndexVal);
            }
          }
        }
      },
    };

    const id = filter["filterId"];
    const name = document.querySelector(`#${id} legend`).textContent;
    this.allFilterNames.add(name);
    const type = this.getFilterTypeFromId(id);
    try {
      // Call the functions based off of the filter type
      methods[type].apply(null);
      return true;
    } catch (e) {
      console.log("ERROR in processFiltersForCaption " + e);
      return false;
    }
  }

  /**
   * Utility function to get a filter type from an id
   * @param id
   * @returns {string}
   */
  getFilterTypeFromId(id) {
    return id.replace(/(^ss)|(\d+(_\d+)?)$/gi, "").toLowerCase();
  }
}

let Sch;
window.Sch = Sch;

window.addEventListener("load", () => {
  Sch = new WildeSearch();
});
