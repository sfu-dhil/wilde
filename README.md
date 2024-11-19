# Wilde Trials

The application for the Wilde Trials project. As of Nov 2024, this project has been revised substantially as a static web application. Remnants of the eXist-db application can be found in the `archive` directory.

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