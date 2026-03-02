import 'package:http/http.dart' as http;
import 'dart:convert';

class GeminiService {
  static const String apiKey = "AIzaSyDFFwXxygLlkLKngn04fBnGcp8eozu6YIA";
  static const String baseUrl =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent";

  static Future<String> generateSchedule(
    List<Map<String, dynamic>> tasks, {
    String startTime = "08:00",
  }) async {
    try {
      final prompt = _buildPrompt(tasks, startTime: startTime);
      final url = Uri.parse('$baseUrl?key=$apiKey');

      final requestBody = {
        "contents": [
          {
            "parts": [
              {"text": prompt},
            ],
          },
        ],
        "generationConfig": {
          "temperature": 0.75,
          "topK": 40,
          "topP": 0.95,
          "maxOutputTokens": 2048,
        },
      };

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["candidates"] != null &&
            data["candidates"].isNotEmpty &&
            data["candidates"][0]["content"] != null &&
            data["candidates"][0]["content"]["parts"] != null &&
            data["candidates"][0]["content"]["parts"].isNotEmpty) {
          return data["candidates"][0]["content"]["parts"][0]["text"] as String;
        }
        return "Tidak ada jadwal yang dihasilkan dari AI.";
      } else {
        if (response.statusCode == 429) {
          throw Exception(
              "Rate limit tercapai (429). Tunggu beberapa menit atau upgrade quota.");
        }
        if (response.statusCode == 401) {
          throw Exception("API key tidak valid (401). Periksa key Anda.");
        }
        if (response.statusCode == 400) {
          throw Exception("Request salah format (400): ${response.body}");
        }
        throw Exception(
            "Gagal memanggil Gemini API (Code: ${response.statusCode})");
      }
    } catch (e) {
      throw Exception("Error saat generate jadwal: $e");
    }
  }

  static String _buildPrompt(
    List<Map<String, dynamic>> tasks, {
    required String startTime,
  }) {
    // Sort tasks: high priority first
    final sorted = List<Map<String, dynamic>>.from(tasks);
    final order = {"Tinggi": 0, "Sedang": 1, "Rendah": 2};
    sorted.sort((a, b) =>
        (order[a['priority']] ?? 2).compareTo(order[b['priority']] ?? 2));

    String taskList = sorted.map((e) {
      final emoji = e['priority'] == 'Tinggi'
          ? '🔴'
          : e['priority'] == 'Sedang'
              ? '🟡'
              : '🟢';
      return "- $emoji ${e['name']} | Durasi: ${e['duration']} menit | Prioritas: ${e['priority']}";
    }).join("\n");

    return """
Kamu adalah asisten penjadwalan AI yang cerdas dan berpengalaman.

Buatkan jadwal harian yang efisien dan terstruktur berdasarkan tugas berikut:
Waktu Mulai: **$startTime WIB**

**Daftar Tugas:**
$taskList

**ATURAN WAJIB:**
1. Format output: **Markdown Table** dengan 4 kolom:
   | ⏰ Waktu | ✅ Kegiatan | ⏱️ Durasi | 📝 Keterangan |
2. Hitung waktu secara berurutan mulai dari jam $startTime, tambahkan jeda 10 menit antar tugas penting.
3. Tambahkan satu sesi istirahat (15-30 menit) jika total durasi > 120 menit.
4. Gunakan emoji yang relevan di kolom Kegiatan.
5. Di LUAR tabel, tambahkan:
   - Satu baris **motivasi singkat** di awal (bold, italic).
   - Bagian **💡 Tips Produktivitas** dengan 2-3 tips spesifik berdasarkan tugas di atas.
   - **Total waktu**: ringkasan total durasi kegiatan.
6. Tulis dalam Bahasa Indonesia yang ramah dan semangat.
""";
  }
}