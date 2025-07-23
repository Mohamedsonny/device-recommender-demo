
let currentLang = "ar";

const texts = {
  ar: {
    title: "ما هو الجهاز المناسب لك؟",
    submit: "اعرض الترشيحات",
    langToggle: "English"
  },
  en: {
    title: "What device suits you best?",
    submit: "Show Recommendations",
    langToggle: "العربية"
  }
};

function toggleLang() {
  currentLang = currentLang === "ar" ? "en" : "ar";
  updateLang();
}

function updateLang() {
  document.getElementById("title").innerText = texts[currentLang].title;
  document.getElementById("submitBtn").innerText = texts[currentLang].submit;
  document.getElementById("langBtn").innerText = texts[currentLang].langToggle;
  document.documentElement.dir = (currentLang === "ar") ? "rtl" : "ltr";
}

// إعداد المرة الأولى
document.addEventListener("DOMContentLoaded", () => {
  document.getElementById("langBtn").addEventListener("click", toggleLang);
  updateLang();
});

// جزء الترشيحات (مؤقت – بيانات ثابتة)
document.getElementById("deviceForm").addEventListener("submit", event => {
  event.preventDefault();
  const d = document.deviceForm.deviceType.value;
  const u = document.deviceForm.usage.value;
  const b = document.deviceForm.budget.value;
  document.getElementById("result").innerText = 
    (currentLang === "ar")
      ? `نوصي بـ ${d} لاستخدام ${u} بميزانية ${b}.`
      : `We recommend a ${d} for ${u} with a budget of ${b}.`;
});
