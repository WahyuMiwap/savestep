abstract class DatabaseService {
  // CREATE (Membuat data baru)
  Future<void> create(String collection, String id, Map<String, dynamic> data);
  
  // READ ALL (Mengambil semua data dalam sebuah tabel/koleksi)
  Future<List<Map<String, dynamic>>> readAll(String collection);
  
  // READ ONE (Mengambil satu data spesifik)
  Future<Map<String, dynamic>?> read(String collection, String id);
  
  // UPDATE (Mengubah data)
  Future<void> update(String collection, String id, Map<String, dynamic> data);
  
  // DELETE (Menghapus data)
  Future<void> delete(String collection, String id);
}
