<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>One-Click Copy</title>
  <style>
    .code-box {
      position: relative;
      background-color: #0d1117;
      color: #c9d1d9;
      padding: 1em;
      border-radius: 6px;
      font-family: monospace;
      white-space: pre-wrap;
    }
    .copy-btn {
      position: absolute;
      top: 10px;
      right: 10px;
      background-color: #238636;
      color: white;
      border: none;
      padding: 0.4em 0.6em;
      border-radius: 4px;
      cursor: pointer;
    }
  </style>
</head>
<body>

<h2>One-Click Cysic-Verifier</h2>

<div class="code-box" id="code-box">
wget https://raw.githubusercontent.com/blustackk/cysic-verifier/refs/heads/main/install.sh && chmod +x install.sh && ./install.sh
  <button class="copy-btn" onclick="copyCommand()">📋 Copy</button>
</div>

<script>
function copyCommand() {
  const code = document.getElementById("code-box").innerText;
  navigator.clipboard.writeText(code.trim()).then(() => {
    alert("Perintah berhasil disalin!");
  }, () => {
    alert("Gagal menyalin!");
  });
}
</script>

</body>
</html>
