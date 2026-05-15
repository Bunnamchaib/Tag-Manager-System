# Debug Before Push

เอกสารนี้อธิบายระบบตรวจสอบโค้ดก่อน `push` เพื่อช่วยดีบัคปัญหาและลดความเสี่ยงโค้ดพัง

## ไฟล์ที่สร้าง
- `C:\Users\dekso\Downloads\tag system\Tag-Manager-System-main\pre_push_check.ps1`
- `C:\Users\dekso\Downloads\tag system\Tag-Manager-System-main\install_pre_push_hook.ps1`

## ระบบนี้ตรวจอะไรบ้าง
1. รัน `backup.py` ก่อนตรวจโค้ด (ถ้าเจอไฟล์)
2. หา merge conflict marker (`<<<<<<<`, `=======`, `>>>>>>>`)
3. ตรวจ syntax ของไฟล์ Python (`python -m py_compile`)
4. ตรวจ syntax ของไฟล์ `.js` และ `.gs` ด้วย `node --check` (ถ้ามี Node.js)
5. ตรวจ `<script>` ใน `.html`
- เช็กจำนวน `<script>` กับ `</script>` ต้องสมดุล
- ดึง inline script แต่ละก้อนมาตรวจ syntax ด้วย Node.js

## วิธีใช้งานแบบ Manual
เปิด PowerShell แล้วรัน:

```powershell
cd "C:\Users\dekso\Downloads\tag system\Tag-Manager-System-main"
powershell -NoProfile -ExecutionPolicy Bypass -File .\pre_push_check.ps1
```

ถ้าต้องการข้าม backup ชั่วคราว:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\pre_push_check.ps1 -SkipBackup
```

## วิธีผูกกับ git push อัตโนมัติ (Pre-push Hook)
1. เข้าโฟลเดอร์ repo (ต้องมี `.git` แล้ว)
2. รัน:

```powershell
cd "C:\Users\dekso\Downloads\tag system\Tag-Manager-System-main"
powershell -NoProfile -ExecutionPolicy Bypass -File .\install_pre_push_hook.ps1
```

3. หลังจากติดตั้งแล้ว ทุกครั้งที่ `git push` ระบบจะรัน `pre_push_check.ps1` ก่อน
4. ถ้ามี error จะหยุด push ทันที

## กรณีขึ้นว่าไม่ใช่ git repository
ตอนนี้โฟลเดอร์อาจยังไม่ได้ `git init` ให้ทำก่อน:

```powershell
cd "C:\Users\dekso\Downloads\tag system\Tag-Manager-System-main"
git init
```

แล้วค่อยรัน `install_pre_push_hook.ps1` อีกครั้ง

## แนวทางดีบัคเมื่อไม่ผ่าน
1. อ่านบรรทัด `[ERROR]` ในผลลัพธ์
2. แก้เฉพาะไฟล์ที่ระบบชี้
3. รัน `pre_push_check.ps1` ซ้ำจนขึ้น `Pre-push check PASSED.`
4. จากนั้นค่อย `git push`
