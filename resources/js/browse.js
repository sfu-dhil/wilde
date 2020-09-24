/* Small library for browse functions */


let togDiv = document.querySelector('.browse-toggle');
togDiv.classList.add('js');
let togSel = togDiv.querySelector('select');
let alphaBrowseDiv = document.querySelectorAll('.browse-div');
let items =  document.querySelectorAll('.browse-div li');
let countDiv;

togSel.addEventListener('change', e=> {
    let selected = togSel.options[togSel.selectedIndex].value;
    let isName = selected === 'name';
    toggleNames(isName);
    if (isName && countDiv) countDiv.classList.add('hidden');
    if (selected === 'count'){
        if (countDiv){
            countDiv.classList.remove('hidden');
        } else {
            makeCountDiv();
        }
    }
});

function toggleNames(show){
    if (show){
        alphaBrowseDiv.forEach(div => div.classList.remove('hidden'));
    } else {
        alphaBrowseDiv.forEach(div => div.classList.add('hidden'));
    }
}

function makeCountDiv(){
    countDiv = document.createElement('div');
    togDiv.parentNode.appendChild(countDiv);
    let sorted = Array.from(items).sort((a, b) => {
        return getCount(b) - getCount(a);
    })
    let newList = document.createElement('ul');
    newList.classList.add('browse-list');
    countDiv.appendChild(newList);
    sorted.forEach(el => {
        let clone = el.cloneNode(true);
        newList.appendChild(clone);
    });
}

function getCount(el){
    return parseInt(el.getAttribute('data-count'), 10);
}







