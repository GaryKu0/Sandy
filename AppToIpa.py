import os
import shutil
import zipfile

def package_app_to_ipa(app_path, output_path):
    # 檢查.app文件是否存在
    if not os.path.exists(app_path):
        print(f"Error: {app_path} does not exist.")
        return
    
    # 創建 Payload 資料夾
    payload_dir = "Payload"
    if os.path.exists(payload_dir):
        shutil.rmtree(payload_dir)
    
    os.makedirs(payload_dir)

    # 將 .app 文件移動到 Payload 資料夾中
    shutil.copytree(app_path, os.path.join(payload_dir, os.path.basename(app_path)))

    # 壓縮 Payload 資料夾為 zip 文件
    ipa_zip_path = output_path + ".zip"
    with zipfile.ZipFile(ipa_zip_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
        for root, dirs, files in os.walk(payload_dir):
            for file in files:
                file_path = os.path.join(root, file)
                zipf.write(file_path, os.path.relpath(file_path, os.path.join(payload_dir, '..')))

    # 重命名 zip 文件為 ipa
    ipa_path = output_path + ".ipa"
    os.rename(ipa_zip_path, ipa_path)

    # 刪除 Payload 資料夾
    shutil.rmtree(payload_dir)

    print(f"IPA file created: {ipa_path}")

# 使用範例
app_path = "/Users/kuosuko/Downloads/Sandy.app/Wrapper/Sandy.app"  # 這裡填寫你的 .app 路徑
output_path = "/Users/kuosuko/Downloads/Sandy"  # 這裡填寫你希望輸出的 .ipa 路徑

package_app_to_ipa(app_path, output_path)