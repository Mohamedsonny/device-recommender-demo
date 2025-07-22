
let currentLanguage = "ar";

const texts = {
  ar: {'title': 'مساعد اختيار الأجهزة', 'question1': 'ما نوع الجهاز الذي تبحث عنه؟', 'question2': 'ما هي الميزانية المتاحة؟', 'question3': 'ما الاستخدام الأساسي للجهاز؟', 'question4': 'هل تفضل علامة تجارية معينة؟', 'question5': 'هل يهمك عمر البطارية؟', 'question6': 'هل تهتم بالأداء العالي؟', 'question7': 'هل تفضل حجماً معيناً؟', 'question8': 'هل تحتاج الجهاز للاستخدام في العمل أم الترفيه؟', 'question9': 'هل تفضل أجهزة تعمل بنظام تشغيل معين؟', 'question10': 'هل تفضل شراء الجهاز أونلاين أم من متجر فعلي؟', 'submit': 'اعرض الترشيحات', 'language_toggle': 'English'},
  en: {'title': 'Device Recommendation Assistant', 'question1': 'What type of device are you looking for?', 'question2': 'What is your available budget?', 'question3': 'What is the main use of the device?', 'question4': 'Do you prefer a specific brand?', 'question5': 'Is battery life important to you?', 'question6': 'Do you care about high performance?', 'question7': 'Do you prefer a specific size?', 'question8': 'Will you use the device for work or entertainment?', 'question9': 'Do you prefer a specific operating system?', 'question10': 'Do you prefer buying online or from a physical store?', 'submit': 'Show Recommendations', 'language_toggle': 'العربية'}
};

document.getElementById("language-toggle").addEventListener("click", () => {
    currentLanguage = currentLanguage === "ar" ? "en" : "ar";
    updateLanguage(currentLanguage);
});

function updateLanguage(lang) {
    document.getElementById("title").innerText = texts[lang].title;
    document.getElementById("question1-label").innerText = texts[lang].question1;
    document.getElementById("question2-label").innerText = texts[lang].question2;
    document.getElementById("question3-label").innerText = texts[lang].question3;
    document.getElementById("question4-label").innerText = texts[lang].question4;
    document.getElementById("question5-label").innerText = texts[lang].question5;
    document.getElementById("question6-label").innerText = texts[lang].question6;
    document.getElementById("question7-label").innerText = texts[lang].question7;
    document.getElementById("question8-label").innerText = texts[lang].question8;
    document.getElementById("question9-label").innerText = texts[lang].question9;
    document.getElementById("question10-label").innerText = texts[lang].question10;
    document.querySelector("button[type='submit']").innerText = texts[lang].submit;
    document.getElementById("language-toggle").innerText = texts[lang].language_toggle;
}
