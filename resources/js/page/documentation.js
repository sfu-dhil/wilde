/*  Page for some small adjustments for the documentation page  */


// Set up the TOC to do smooth scrolling, when possible:

const toc = document.getElementById('toc');
const links = toc.querySelectorAll('a[href^="#"]'); 

links.forEach(link => {
   link.addEventListener('click', e => {
      e.preventDefault();
      document.querySelector(link.getAttribute('href')).scrollIntoView({behavior: "smooth"});
   });
});

