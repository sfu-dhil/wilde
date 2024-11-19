import StickyElements from "../lib/dhilux/js/sticky_elements.js"


document.addEventListener('DOMContentLoaded', () => {
  
let stickyEls = new StickyElements('thead > tr');
const tbl = document.querySelector('#tbl-browser')
if (tbl){
  tbl.classList.add('sortable-theme-bootstrap');
  Sortable.initTable(tbl);
}

  
})