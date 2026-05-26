# 工具脚本

## 生成出生地点库

数据来源：[qwd/LocationList](https://github.com/qwd/LocationList) `China-City-List-latest.csv`（约 3200+ 省 / 市 / 区县）。

```bash
# 可选：将 CSV 保存为 tool/china_cities_raw.txt 后离线生成
python tool/generate_birth_places.py
```

输出：`lib/infrastructure/geo/china_birth_places_data.dart`
