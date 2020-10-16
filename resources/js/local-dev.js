if (window.location.hostname === '0.0.0.0'){
    let docs = ['city','date','language', 'newspaper', 'region', 'source'];
    docs.forEach(doc => {
        let q = 'a[href="' + doc +'.html"]';
        let links = document.querySelectorAll(q);
        links.forEach(link => {
            link.setAttribute('href', doc + "-nocache.html");
        });
    });
}


