
document.getElementById('deviceForm').addEventListener('submit', function(e) {
    e.preventDefault();
    let form = e.target;
    let device = form.deviceType.value;
    let budget = form.budget.value;
    let usage = form.usage.value;
    let brand = form.brand.value;

    let result = "Recommended " + device + " for " + usage + " in budget: " + budget + ". Preferred brand: " + brand + ".";
    document.getElementById('result').innerText = result;
});
