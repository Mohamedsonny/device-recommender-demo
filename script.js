
document.addEventListener("DOMContentLoaded", function () {
    const langToggleBtn = document.getElementById("lang-toggle");
    const title = document.getElementById("title");
    const labelCategory = document.getElementById("label-category");
    const submitBtn = document.getElementById("submit-btn");
    const resultsTitle = document.getElementById("results-title");
    const categorySelect = document.getElementById("category");
    const form = document.getElementById("question-form");
    const resultsContainer = document.getElementById("results-container");
    const dynamicQuestions = document.getElementById("dynamic-questions");

    let currentLang = "ar";

    const translations = {
        ar: {
            title: "مرحبًا بك في مُرشح الأجهزة",
            labelCategory: "اختر نوع الجهاز:",
            submitBtn: "عرض الترشيحات",
            resultsTitle: "الترشيحات",
            langButton: "English"
        },
        en: {
            title: "Welcome to Device Recommender",
            labelCategory: "Select device type:",
            submitBtn: "Show Recommendations",
            resultsTitle: "Recommendations",
            langButton: "العربية"
        }
    };

    const questionsByCategory = {
        laptop: [
            { id: "budget", label: { ar: "ما ميزانيتك؟", en: "What's your budget?" }, type: "select", options: ["10000", "20000", "30000+"] },
            { id: "use", label: { ar: "ما استخدامك الأساسي؟", en: "What's your primary use?" }, type: "select", options: ["تصميم", "ألعاب", "تصفح"] }
        ],
        mobile: [
            { id: "budget", label: { ar: "ما ميزانيتك؟", en: "What's your budget?" }, type: "select", options: ["5000", "10000", "15000+"] },
            { id: "camera", label: { ar: "هل تفضل كاميرا ممتازة؟", en: "Do you prefer a great camera?" }, type: "select", options: ["نعم", "لا"] }
        ]
    };

    const products = {
        laptop: [
            { name: "HP Pavilion", price: 20000 },
            { name: "Lenovo Legion", price: 30000 }
        ],
        mobile: [
            { name: "Samsung Galaxy A15", price: 9500 },
            { name: "Infinix Note 40", price: 7999 }
        ]
    };

    function updateLanguage() {
        const t = translations[currentLang];
        title.textContent = t.title;
        labelCategory.textContent = t.labelCategory;
        submitBtn.textContent = t.submitBtn;
        resultsTitle.textContent = t.resultsTitle;
        langToggleBtn.textContent = t.langButton;
        renderDynamicQuestions();
    }

    langToggleBtn.addEventListener("click", () => {
        currentLang = currentLang === "ar" ? "en" : "ar";
        document.documentElement.lang = currentLang;
        document.documentElement.dir = currentLang === "ar" ? "rtl" : "ltr";
        updateLanguage();
    });

    categorySelect.addEventListener("change", renderDynamicQuestions);

    function renderDynamicQuestions() {
        const selectedCategory = categorySelect.value;
        const questions = questionsByCategory[selectedCategory] || [];
        dynamicQuestions.innerHTML = "";
        questions.forEach(q => {
            const label = document.createElement("label");
            label.textContent = q.label[currentLang];
            const select = document.createElement("select");
            select.name = q.id;
            q.options.forEach(opt => {
                const option = document.createElement("option");
                option.value = opt;
                option.textContent = opt;
                select.appendChild(option);
            });
            dynamicQuestions.appendChild(label);
            dynamicQuestions.appendChild(select);
        });
    }

    form.addEventListener("submit", function (e) {
        e.preventDefault();
        const category = categorySelect.value;
        const selectedProducts = products[category] || [];
        resultsContainer.innerHTML = "";
        selectedProducts.forEach(product => {
            const div = document.createElement("div");
            div.className = "product";
            div.innerHTML = `<strong>${product.name}</strong> - ${product.price} EGP`;
            resultsContainer.appendChild(div);
        });
    });

    // Initial render
    renderDynamicQuestions();
});
