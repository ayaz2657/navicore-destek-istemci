#!/usr/bin/env python3
"""Upstream .github/workflows/flutter-build.yml'den yalniz Windows x64 NaviCore workflow'u uretir.
Kullanim (repo kokunden): python3 navicore/gen_workflow.py
Upstream yapisi degisirse assert'ler patlar -> elle kontrol edilir."""
import re
W = ".github/workflows/"
src = open(W + "flutter-build.yml", encoding="utf-8").read().split("\n")
idx = lambda pred: next(i for i, l in enumerate(src) if pred(l))
env_s = idx(lambda l: l.startswith("env:")); jobs_s = idx(lambda l: l.startswith("jobs:"))
env = "\n".join(src[env_s:jobs_s])
for a, b in [('TAG_NAME: "${{ inputs.upload-tag }}"', 'TAG_NAME: "navicore"'),
             ('UPLOAD_ARTIFACT: "${{ inputs.upload-artifact }}"', 'UPLOAD_ARTIFACT: "true"'),
             ('PUBLISH_UPDATE_METADATA: "${{ inputs.publish-update-metadata }}"', 'PUBLISH_UPDATE_METADATA: "false"')]:
    assert env.count(a) == 1, a; env = env.replace(a, b)
assert "inputs." not in env
w_s = idx(lambda l: l.startswith("  build-for-windows-flutter:"))
w_e = next(i for i in range(w_s, len(src)) if src[i].strip() == "- name: Add MSBuild to PATH")
win = "\n".join(src[w_s:w_e]).rstrip() + "\n"
win = re.sub(r"\n          - \{\n              target: aarch64-pc-windows-msvc,.*?\n            \}", "", win, flags=re.S)
assert "aarch64-pc-windows-msvc" not in win
win = win.replace("${{ !inputs.upload-artifact && matrix.job.arch == 'x86_64' }}", "false").replace("${{ inputs.upload-artifact }}", "true")
assert "inputs." not in win
anchor = "      - name: Checkout source code\n        uses: actions/checkout@34e114876b0b11c390a56381ad16ebd13914f8d5 # v4\n        with:\n          submodules: recursive\n"
assert win.count(anchor) == 1, "checkout adimi degismis"
win = win.replace(anchor, anchor + "\n      - name: NaviCore branding\n        shell: bash\n        run: bash navicore/brand.sh\n")
# Ana exe'yi uygulama adiyla paketle: ilk kurulum (install_me) klasoru XCOPY ile kopyalar ve yeniden adlandirmaz,
# servis/kisayollar ise {APP_NAME}.exe bekler (windows.rs install_me / rename_exe_cmd yalniz guncellemede).
pk = "      - name: Build self-extracted executable\n"
assert win.count(pk) == 1, "packer adimi degismis"
win = win.replace(pk, """      - name: NaviCore exe adi (APP_NAME.exe)
        shell: bash
        run: |
          APP=$(grep -E '^APP_NAME=' navicore/brand.env | cut -d= -f2)
          [ -f ./rustdesk/rustdesk.exe ] || { echo "rustdesk.exe yok"; exit 1; }
          mv ./rustdesk/rustdesk.exe "./rustdesk/$APP.exe"
          echo "NAVICORE_EXE=$APP.exe" >> "$GITHUB_ENV"

""" + pk)
old_e = "python3 ./generate.py -f ../../rustdesk/ -o . -e ../../rustdesk/rustdesk.exe"
assert win.count(old_e) == 1, "generate.py -e degismis"
win = win.replace(old_e, 'python3 ./generate.py -f ../../rustdesk/ -o . -e "../../rustdesk/${{ env.NAVICORE_EXE }}"')
head = open("navicore/workflow_head.yml", encoding="utf-8").read()
tail = open("navicore/workflow_tail.yml", encoding="utf-8").read()
open(W + "navicore-windows.yml", "w", encoding="utf-8").write(head + env + "\n" + tail.split("#--WIN--\n")[0] + win.rstrip("\n") + "\n" + tail.split("#--WIN--\n")[1])
print("uretildi:", W + "navicore-windows.yml")
