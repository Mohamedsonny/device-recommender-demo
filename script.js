let currentLanguage = 'ar';
let questions = {
  ar: {
    deviceType: "ما نوع الجهاز الذي تبحث عنه؟",
    priceRange: "ما هو نطاق السعر المفضل؟",
    brandPreference: "هل تفضل علامة تجارية معينة؟",
    usage: "ما هو الغرض الأساسي من الجهاز؟",
    portability: "هل تفضل جهاز محمول؟",
    performance: "ما مستوى الأداء المطلوب؟",
    screenSize: "ما حجم الشاشة المفضل؟",
    battery: "ما مدى أهمية عمر البطارية؟",
    storage: "كم سعة التخزين التي تحتاجها؟",
    camera: "هل جودة الكاميرا مهمة؟"
  },
  en: {
    deviceType: "What type of device are you looking for?",
    priceRange: "What is your preferred price range?",
    brandPreference: "Do you prefer a specific brand?",
    usage: "What is the primary use of the device?",
    portability: "Do you prefer a portable device?",
    performance: "What performance level do you need?",
    screenSize: "What screen size do you prefer?",
    battery: "How important is battery life?",
    storage: "How much storage do you need?",
    camera: "Is camera quality important?"
  }
};

let options = {
  deviceType: {
    ar: ["موبايل", "لاب توب", "تابلت", "تلفزيون"],
    en: ["Mobile", "Laptop", "Tablet", "TV"]
  },
  priceRange: {
    ar: ["أقل من 5000", "5000 - 10000", "أعلى من 10000"],
    en: ["Under 5000", "5000 - 10000", "Above 10000"]
  },
  brandPreference: {
    ar: ["لا يهم", "سامسونج", "شاومي", "أبل", "لينوفو", "ديل"],
    en: ["No Preference", "Samsung", "Xiaomi", "Apple", "Lenovo", "Dell"]
  },
  usage: {
    ar: ["عام", "للألعاب", "للشغل", "للدراسة"],
    en: ["General", "Gaming", "Work", "Study"]
  }
};

function toggleLanguage() {
  currentLanguage = currentLanguage === 'ar' ? 'en' : 'ar';
  document.getElementById("language-label").textContent = currentLanguage === 'ar' ? 'العربية' : 'English';
  document.getElementById("title").textContent =
    currentLanguage === 'ar' ? 'اختر الجهاز المناسب لك' : 'Choose the right device for you';
  renderQuestions();
}

function renderQuestions() {
  const form = document.getElementById("questionnaire");
  form.innerHTML = "";
  const q = questions[currentLanguage];
  const lang = currentLanguage;

  for (let key in q) {
    const label = document.createElement("label");
    label.textContent = q[key];
    const select = document.createElement("select");
    select.name = key;
    (options[key] ? options[key][lang] : ["نعم", "لا"]).forEach(opt => {
      const option = document.createElement("option");
      option.value = opt;
      option.text = opt;
      select.appendChild(option);
    });
    form.appendChild(label);
    form.appendChild(select);
    form.appendChild(document.createElement("br"));
  }
}

function getRecommendations() {
  const selects = document.querySelectorAll("#questionnaire select");
  let answers = {};
  selects.forEach(sel => {
    answers[sel.name] = sel.value;
  });

  fetch("products.json")
    .then(res => res.json())
    .then(data => {
      let filtered = data.filter(product => {
        return product.type === answers.deviceType &&
               product.priceRange === answers.priceRange &&
               product.usage.includes(answers.usage);
      });

      let output = "<h2>الترشيحات:</h2>";
      if (filtered.length === 0) output += "<p>لا توجد نتائج مطابقة</p>";
      filtered.forEach(p => {
        output += `<div><h3>${p.name}</h3><p>${p.description}</p><a href="${p.link}" target="_blank">رابط الشراء</a></div><hr/>`;
      });
      document.getElementById("recommendations").innerHTML = output;
    });
}

window.onload = () => {
  renderQuestions();
};
