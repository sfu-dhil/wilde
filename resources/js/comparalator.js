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

$(function () {
  $('[data-toggle="tooltip1"]').tooltip();
  $('[data-toggle="popover"]').popover();
})


// Actual code follows:
$(window).ready(function() {
  console.log("starting comparalator.");

  startComparalator();
});
//
// $(document).on('click', '.comparalator-add', function() {
//
// });

$(document).on('mousedown', '.selected-text', function() {
  console.log("unwrapping");

  unwrapSelectedText();
});


$(document).on('mouseup', '#original', function() {
  $('.popover').remove();
  console.log("moused up");
  // console.log("selectedText: " + getSelectionText());

  var selectedText = window.getSelection();

  if (selectedText != "") {
    console.log("selectedText: " + selectedText);

    // var selectedTextRange = selectedText.getRangeAt(0); //get the text range
    // var selectedTextPos = selectedTextRange.getBoundingClientRect();
    // console.log(selectedTextPos);
    var highlight = window.getSelection(),
      spn = $('<span class="selected-text" data-toggle="popover" title="selected text" data-placement="top auto"></span>')[0],
      range = highlight.getRangeAt(0);
    range.surroundContents(spn);

    $('[data-toggle="popover"]').popover('show'); // reinitialize popovers

    // selectedTextString = selectedText.toString();
  }
});



function startComparalator() {
  if ($('.panel-metadata').length > 0) {
    if ($('#comparalator').length == 0) {
      $('body').append('<div id="comparalator"></div>');
      $('#comparalator').append('<div class="top"><h3>Comparalator</h3></div><div class="bottom"><button class="comparalator-add">Compare selected text</button></div>');
      $('#comparalator .top').append('<div class="comparalator-text comparalator-text-1"><span data-toggle="tooltip" title="Empty">Text 1</span><button class="comparalator-clear">X</button></div>');
      $('#comparalator .top').append('<div class="comparalator-text comparalator-text-2"><span data-toggle="tooltip" title="Empty">Text 2</span><button class="comparalator-clear">X</button></div>');
    }
  }
}

function unwrapSelectedText() {
  $('.popover').remove();
  $('.selected-text').each(function() {
    var text = $(this).text();
    $(this).replaceWith(text);
  });
}



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

//
// function getSelectionText() {
//     var selectedTextString = ""
//
//     return selectedTextString;
// }
