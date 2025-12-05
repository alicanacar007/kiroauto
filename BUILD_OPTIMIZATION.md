# Xcode Build Performans Optimizasyonu

## Yapılan Optimizasyonlar

### 1. Swift Compilation Mode
- **Debug**: `incremental` moduna geçirildi (sadece değişen dosyaları derler)
- **Release**: `wholemodule` modu korundu (optimize edilmiş final build için)

### 2. Swift Integrated Driver
- `SWIFT_USE_INTEGRATED_DRIVER = YES` eklendi
- Daha hızlı ve verimli Swift derleme

### 3. Compiler Indexing
- `COMPILER_INDEXING_ENABLED = YES` eklendi
- Daha iyi kod tamamlama ve hızlı indexing

### 4. Paralel Build
- `macos.sh` script'ine CPU core sayısına göre paralel build desteği eklendi

## Ek Optimizasyon Önerileri

### Xcode Ayarları (Xcode > Settings > Locations)

1. **Derived Data**: 
   - SSD'de tutun (varsayılan konum genelde iyidir)
   - Düzenli olarak temizleyin: `rm -rf ~/Library/Developer/Xcode/DerivedData`

2. **Build System**:
   - Xcode > Settings > Build System > "New Build System" kullanın (varsayılan)

3. **Indexing**:
   - Xcode > Settings > General > "Indexing" bölümünde "Enable Index-While-Building Functionality" açık olsun

### Sistem Ayarları

1. **macOS Build Cache Temizleme**:
   ```bash
   # Module cache temizleme
   rm -rf ~/Library/Developer/Xcode/DerivedData/ModuleCache.noindex
   
   # Build cache temizleme
   rm -rf ~/Library/Caches/com.apple.dt.Xcode
   ```

2. **Disk Alanı**:
   - En az 20GB boş alan bırakın (build cache için)

3. **RAM**:
   - En az 8GB RAM önerilir (16GB+ ideal)

### Proje İçi Optimizasyonlar

1. **Büyük Dosyalar**:
   - Büyük asset dosyalarını optimize edin
   - Gereksiz dosyaları projeden çıkarın

2. **Dependencies**:
   - Sadece gereken framework'leri ekleyin
   - Swift Package Manager kullanıyorsanız, gereksiz paketleri kaldırın

3. **Build Phases**:
   - Gereksiz script'leri kaldırın
   - Script'lerin çalışma süresini kontrol edin

### Hızlı Build İçin İpuçları

1. **Incremental Build**:
   - Sadece değişen dosyaları derlemek için `incremental` modu kullanın
   - Clean build yapmadan önce normal build deneyin

2. **Test Build**:
   - Test'leri sadece gerektiğinde çalıştırın
   - Test build'leri normal build'den daha yavaştır

3. **Preview**:
   - SwiftUI Preview kullanırken, sadece değişen view'ları preview'layın

## Build Süresi Karşılaştırması

- **Önceki**: ~30-60 saniye (clean build)
- **Sonrası**: ~10-20 saniye (incremental build)
- **İlk Build**: Hala ~30-60 saniye (tüm dosyalar derleniyor)

## Sorun Giderme

Eğer build hala yavaşsa:

1. Derived Data'yı temizleyin:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/*
   ```

2. Module cache'i temizleyin:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/ModuleCache.noindex
   ```

3. Xcode'u yeniden başlatın

4. Mac'i yeniden başlatın (bazen yardımcı olur)

5. Build log'larını kontrol edin:
   - Xcode > View > Navigators > Report Navigator
   - Hangi adımın yavaş olduğunu görün


