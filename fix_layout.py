import sys

file_path = 'd:/AndroidProject/LatihanFlutter/sadayana-masjid-tv/landingpage/panduan.html'
with open(file_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Fix 1: Delete the corrupted block
start_idx = -1
for i, line in enumerate(lines):
    if 'Cara Masuk ke Pengaturan — #akses-settings' in line:
        start_idx = i - 1  # The comment line above it
        break

end_idx = -1
if start_idx != -1:
    for i in range(start_idx + 2, len(lines)):
        if 'Cara Masuk ke Pengaturan — #akses-settings' in line:
            end_idx = i - 1
            break

if start_idx != -1 and end_idx != -1:
    print(f'Deleting lines from {start_idx} to {end_idx - 1}')
    del lines[start_idx:end_idx]
else:
    print('Could not find duplicate block')

# Fix 2: Fix the Jika PIN Aktif missing tags
for i, line in enumerate(lines):
    if 'halaman PIN muncul — masukkan 6 digit PIN yang benar' in line:
        # Check if the next line is the broken one
        if 'class="mb-3"' in lines[i+1]:
            print('Fixing Jika PIN Aktif block')
            # Insert the missing tags
            lines.insert(i+1, '                  </span>\n                </li>\n              </ul>\n            </div>\n          </div>\n          <div class="col-md-6 col-lg-5">\n            <div class="card-mkt p-4 h-100">\n              <h3 class="h6 fw-bold mkt-text-primary mb-3">Mengelola PIN</h3>\n              <p class="mkt-text-secondary mb-3" style="font-size: 0.9rem">\n                Buat, ubah, atau nonaktifkan PIN melalui menu pengaturan:\n              </p>\n              <p\n')
            break

with open(file_path, 'w', encoding='utf-8') as f:
    f.writelines(lines)

print('Done')
