// ==UserScript==
// @name Comparalator Prototype
// @namespace https://dhil.lib.sfu.ca
// @version 0.1
// @description Adds an easy compare function to the Wilde Trials DHIL site.
// @match https://dhil.lib.sfu.ca/wilde/*
// @include https://dhil.lib.sfu.ca/wilde/*
// @grant none
// @supportURL catherine_winters@sfu.ca
// ==/UserScript==

// Actual code follows:
$(window).ready(function() {
    console.log("starting comparalator.");

    startComparalator();
});

$(document).on('click', '.comparealator-add', function() {
    var selectedText = "";
    selectedText = getSelectionText();
    if (selectedText != "") {
        console.log(getSelectionText());

        // test if comparalator1 is already set.

        // if not, set it.

        // test if comparalator2 is already set.
    }
    else {
        console.log("No text selected");
    }
});

$(document).on('mouseup', '#original', function() {
    console.log("moused up");
});



function startComparalator() {
    if ($('#comparalator').length == 0) {
        $('body').append('<div id="comparalator"></div>');
        $('#comparalator').append('<div class="top"><h3>Comparalator</h3></div><div class="bottom"><button class="comparalator-add">Compare selected text</button></div>');
        $('#comparalator .top').append('<div class="comparalator-text comparalator-text-1"><span data-toggle="tooltip" title="Empty">Text 1</span><button class="comparalator-clear">X</button></div>');
        $('#comparalator .top').append('<div class="comparalator-text comparalator-text-2"><span data-toggle="tooltip" title="Empty">Text 2</span><button class="comparalator-clear">X</button></div>');
    }
});



function resetComparalator1() {
    document.cookie = "comparalator1=; expires=Thu, 01 Jan 1970 00:00:00 GMT";
    $('.comparalator-text-1 span').attr('title', 'Empty');
    console.log("Cleared text 1");
}

function resetComparalator2() {
    document.cookie = "comparalator2=; expires=Thu, 01 Jan 1970 00:00:00 GMT";
    $('.comparalator-text-2 span').attr('title', 'Empty');
    console.log("Cleared text 2");
}


function getSelectionText() {
    var selectedText = ""
    if (window.getSelection) { // all modern browsers and IE9+
        selectedText = window.getSelection().toString()
    }
    return selectedText
}
