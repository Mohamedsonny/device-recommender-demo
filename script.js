
// دالة لتحميل وعرض المنتجات من ملف JSON
async function loadProducts() {
    try {
        const response = await fetch('products.json');
        const data = await response.json();

        const container = document.getElementById('product-results');
        container.innerHTML = '';

        data.forEach(product => {
            const item = document.createElement('div');
            item.className = 'product-card';
            item.innerHTML = `
                <h3>${product.title}</h3>
                <img src="${product.image}" alt="${product.title}" style="max-width: 150px;">
                <p><strong>الموقع:</strong> ${product.site}</p>
                <p><strong>السعر:</strong> ${product.price} جنيه</p>
                <a href="${product.link}" target="_blank">رابط المنتج</a>
                <hr/>
            `;
            container.appendChild(item);
        });
    } catch (error) {
        console.error('خطأ في تحميل المنتجات:', error);
    }
}

// تنفيذ الدالة عند تحميل الصفحة
window.onload = loadProducts;
