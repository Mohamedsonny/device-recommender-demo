let currentLanguage = 'ar';

const translations = {
  ar: {
    title: "اختر نوع الجهاز",
    questions: {
      deviceType: "ما نوع الجهاز؟",
      budget: "ما ميزانيتك؟",
      usage: "ما هو الاستخدام الأساسي؟"
    },
    options: {
      deviceType: ["موبايل", "لاب توب"],
      budget: {
        "موبايل": ["أقل من 5000", "5000 - 10000", "أعلى من 10000"],
        "لاب توب": ["5000 - 10000", "10000 - 20000", "أعلى من 20000"]
      },
      usage: ["عام", "للألعاب", "للشغل", "للدراسة"]
    },
    submit: "عرض الترشيحات",
    recommendations: "الترشيحات:"
  },
  en: {
    title: "Choose Device Type",
    questions: {
      deviceType: "What type of device?",
      budget: "What's your budget?",
      usage: "What's the main usage?"
    },
    options: {
      deviceType: ["Mobile", "Laptop"],
      budget: {
        "Mobile": ["Under 5000", "5000 - 10000", "Above 10000"],
        "Laptop": ["5000 - 10000", "10000 - 20000", "Above 20000"]
      },
      usage: ["General", "Gaming", "Work", "Study"]
    },
    submit: "Show Recommendations",
    recommendations: "Recommendations:"
  }
};

function toggleLanguage() {
  currentLanguage = currentLanguage === 'ar' ? 'en' : 'ar';
  document.getElementById('language-label').textContent = currentLanguage === 'ar' ? 'العربية' : 'English';
  document.getElementById('title').textContent = translations[currentLanguage].title;
  renderForm();
}

function renderForm() {
  const form = document.getElementById('questionnaire');
  form.innerHTML = '';
  const t = translations[currentLanguage];

  const deviceSelect = createSelect('deviceType', t.questions.deviceType, t.options.deviceType);
  form.appendChild(deviceSelect.label);
  form.appendChild(deviceSelect.select);

  const budgetWrapper = document.createElement('div');
  budgetWrapper.id = 'budget-wrapper';
  form.appendChild(budgetWrapper);

  const usageSelect = createSelect('usage', t.questions.usage, t.options.usage);
  form.appendChild(usageSelect.label);
  form.appendChild(usageSelect.select);

  document.querySelector('button').textContent = t.submit;

  deviceSelect.select.addEventListener('change', () => {
    const selectedDevice = deviceSelect.select.value;
    const budgetOptions = t.options.budget[selectedDevice] || [];
    budgetWrapper.innerHTML = '';
    const budgetSelect = createSelect('budget', t.questions.budget, budgetOptions);
    budgetWrapper.appendChild(budgetSelect.label);
    budgetWrapper.appendChild(budgetSelect.select);
  });

  deviceSelect.select.dispatchEvent(new Event('change'));
}

function createSelect(name, labelText, options) {
  const label = document.createElement('label');
  label.textContent = labelText;
  const select = document.createElement('select');
  select.name = name;
  options.forEach(opt => {
    const option = document.createElement('option');
    option.value = opt;
    option.textContent = opt;
    select.appendChild(option);
  });
  return { label, select };
}

function getRecommendations() {
  const selects = document.querySelectorAll('select');
  let answers = {};
  selects.forEach(sel => answers[sel.name] = sel.value);

  fetch('products.json')
    .then(res => res.json())
    .then(products => {
      const resultBox = document.getElementById('recommendations');
      const t = translations[currentLanguage];
      let matched = products.filter(p =>
        p.type === answers.deviceType &&
        p.budget === answers.budget &&
        p.usage.includes(answers.usage)
      );

      let html = `<h3>${t.recommendations}</h3>`;
      if (matched.length === 0) {
        html += `<p>No results found.</p>`;
      } else {
        matched.forEach(p => {
          html += `<div><h4>${p.name}</h4><p>${p.description}</p><a href="${p.link}" target="_blank">Link</a></div>`;
        });
      }
      resultBox.innerHTML = html;
    });
}

window.onload = renderForm;