// 1. ฟังก์ชันส่งออกข้อมูลเป็น JSON ให้ Frontend ดึงไปใช้
function doGet(e) {
  var sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName("Database");
  if (!sheet) {
    return ContentService.createTextOutput(JSON.stringify({error: "ไม่พบชีต 'Database'"}))
                         .setMimeType(ContentService.MimeType.JSON);
  }
  
  var data = sheet.getDataRange().getValues();
  var headers = data[0];
  var result = [];
  
  for (var i = 1; i < data.length; i++) {
    var obj = {};
    for (var j = 0; j < headers.length; j++) {
      obj[headers[j]] = data[i][j];
    }
    result.push(obj);
  }
  
  return ContentService.createTextOutput(JSON.stringify(result))
                       .setMimeType(ContentService.MimeType.JSON);
}

// 2. ฟังก์ชันสำหรับสร้างฐานข้อมูลเริ่มต้น (รันแค่ครั้งแรก)
function setupInitialData() {
  var ss = SpreadsheetApp.getActiveSpreadsheet();
  var sheet = ss.getSheetByName("Database");
  
  if (!sheet) {
    sheet = ss.insertSheet("Database");
  } else {
    sheet.clear();
  }

  // กำหนด Header
  var headers = ["Model", "Part name", "Part no", "Qty pcs", "Customer", "Photo base64", "ID Code"];
  
  // ภาพตัวอย่าง Base64 (ภาพปุ่มหน้าต่างรถยนต์แบบคร่าวๆ หรือภาพดัมมี่)
  var sampleImage = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAGQAAAAeCAYAAADaW7vzAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAC0SURBVGhD7c1BCgAxCATA3f/f7t76BHEoZlEIL/O2zGzG7b0/P/z3RzshhBBCCCGEEEIIIYQQQgghhBBCCCGEEEIIIYQQQgghhBBCCCGEEEIIIYQQQgghhBBCCCGEEEIIIYQQQgghhBBCCCGEEEIIIYQQQgghhBBCCCGEEEIIIYQQQgghhBBCCCGEEEIIIYQQQgghhBBCCCGEEEIIIYQQQgghhBBCCCGEEEIIIYQQQgghhBBCCHnMA6eDAf2135UDAAAAAElFTkSuQmCC"; 
  
  var data = [
    headers,
    ["C857", "FR DOOR BUTTON PANEL BODY,LH", "SCTIDTL-0001", 24, "AIPR", sampleImage, ""],
    ["A123", "REAR BUMPER BRACKET", "RBB-9921", 50, "HONDA", sampleImage, "ID-A123"],
    ["X990", "SIDE MIRROR COVER RH", "SMC-0022", 12, "ISUZU", sampleImage, ""]
  ];

  sheet.getRange(1, 1, data.length, data[0].length).setValues(data);
}