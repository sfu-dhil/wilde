/* Small library for browse functions */


let togDiv = document.querySelector('.browse-toggle');
togDiv.classList.add('js');
let togSel = togDiv.querySelector('select');
let alphaBrowseDiv = document.querySelectorAll('.browse-div');
let items =  document.querySelectorAll('.browse-div [data-count]');
let countDiv;

togSel.addEventListener('change', e=> {
    let selected = togSel.options[togSel.selectedIndex].value;
    let isDefault = (togSel.selectedIndex === 0);
    toggleDefault(isDefault);
    if (isDefault && countDiv) countDiv.classList.add('hidden');
    if (selected === 'count'){
        if (countDiv){
            countDiv.classList.remove('hidden');
        } else {
            makeCountDiv();
        }
    }
});

function toggleDefault(show){

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
    sorted.forEach(el => {
        if (el.tagName === 'A'){
            if (getCount(el) === 0){
                return;
            }
            let newLi = document.createElement('li');
            newLi.appendChild(el.cloneNode(true));

            newList.appendChild(newLi);
            newList.querySelectorAll('.day').forEach(span => {
                span.classList.remove('day')
                span.classList.add('name')
            });
            newList.style.setProperty('--height', '0%');

        } else {
            newList.appendChild(el.cloneNode(true));
        }
    });
    countDiv.classList.add('fade');
    countDiv.appendChild(newList);
    requestAnimationFrame(function(){
        countDiv.classList.add('in');

    });


}


function getCount(el){
    return parseInt(el.getAttribute('data-count'), 10);
}







