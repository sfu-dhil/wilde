# The Wilde Trials News Archive 

> Principal Investigator: Colette Colligan
> The Wilde Trials News Archive is a custom-built textbase and text-sharing detection program for analyzing international news reports about the famous 1895 trials of Anglo-Irish writer Oscar Wilde. This research tool detects, quantifies, and displays text reuse and censorship in international newspapers, allowing users to track the flow of news around the world and across borders and across languages, thus far across 1 million words, 1,000 documents and 10,000 matching paragraphs. Currently in progress, the project's background can be explored [here](https://www.sfu.ca/big-data/stories/discovering-wilde-data/). 

This is the codebase for building The Wild Trials New Archive (data stored separately).

As of Nov 2024, this project has been revised substantially as a static web application using XSLT. Remnants of the eXist-db application can be found in the `archive` directory.

## To build

First, make sure you have the wilde-data repository somewhere nearby (the code assumes it is symlinked into the current directory, but it can live anywhere)

At present, this still uses yarn, so you must do a yarn install:

```
yarn install
```

Then you can build the application using:

```
ant
```

Note if you have put your wilde-data elsewhere, then you can pass that as a parameter:

```
ant -Dreports.dir=path/to/reports-dir
```

In most cases, you will need to give ant more memory to build the entire site including search -- that can be done like so:

```
export ANT_OPTS="-Xmx6G"; ant

```
