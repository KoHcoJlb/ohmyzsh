function fix_vscode {
  for file in ~/.vscode-server/bin/*/node; do
    patchelf --set-interpreter ~/.nix-packages/lib/ld-linux-x86-64.so.2 --set-rpath ~/.nix-packages/lib $file
  done
}
