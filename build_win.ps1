# build full version
cmake -B build -DCMAKE_INSTALL_PREFIX=src/main/resources/windows-x64 -DBUILD_SHARED_LIBS=0 -DGGML_STATIC=1 
cmake --build build --config Release
cmake --install build
rm -r -fo build
mv .\src\main\resources\windows-x64\whisper-jni.dll .\src\main\resources\windows-x64\whisper-jni_full.dll
# build wrapper for external dll version
#cmake -B build -DCMAKE_INSTALL_PREFIX=src/main/resources/windows-x64
#cmake --build build --config Release
#cmake --install build
#rm -r -fo build
rm -r -fo src/main/resources/windows-x64/*.lib
#rm src/main/resources/windows-x64/whisper.dll -Force -ErrorAction SilentlyContinue
#rm src/main/resources/windows-x64/ggml.dll -Force -ErrorAction SilentlyContinue
#rm src/main/resources/windows-x64/cmake -Force -ErrorAction SilentlyContinue
#rm src/main/resources/windows-x64/pkgconfig -Force -ErrorAction SilentlyContinue