const openNav = document.getElementById('openNav');
const closeNav = document.getElementById('closeNav');
const sidebar = document.querySelector('.sidebar');
const container = document.querySelector('.container-fluid');

const callbackClickOutsideSidebar = e => {
    if (!sidebar.contains(e.target)) {
        sidebar.classList.remove('active');
        container.classList.remove('filter');
        document.removeEventListener('click', callbackClickOutsideSidebar);
    }
}

openNav.addEventListener('click', e => {
    e.stopPropagation();
    sidebar.classList.toggle('active');
    container.classList.toggle('filter');
    document.addEventListener('click', callbackClickOutsideSidebar);
});

closeNav.addEventListener('click', e => {
    e.stopPropagation();
    sidebar.classList.remove('active');
    container.classList.remove('filter');
    document.removeEventListener('click', callbackClickOutsideSidebar);
});