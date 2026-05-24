import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pondstat/core/firebase/firebase_providers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

part 'finances_repository.g.dart';

@riverpod
FinancesRepository financesRepository(Ref ref) {
  final baseRef = ref.watch(appBaseRefProvider);
  final auth = ref.watch(firebaseAuthProvider);
  return FinancesRepository(baseRef, auth);
}

class FinancesRepository {
  final DocumentReference<Map<String, dynamic>> _baseRef;
  final FirebaseAuth _auth;

  FinancesRepository(this._baseRef, this._auth);

  User? get currentUser => _auth.currentUser;

  // ─── Collection References ───────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> get expensesCollection =>
      _baseRef.collection('expenses');

  CollectionReference<Map<String, dynamic>> get pondExpensesCollection =>
      _baseRef.collection('pond_expenses');

  CollectionReference<Map<String, dynamic>> get pondSalesCollection =>
      _baseRef.collection('pond_sales');

  // ─── Group Expenses CRUD ──────────────────────────────────────────────

  /// Adds a new expense to Firestore.
  Future<void> addExpense({
    required String pondId,
    required String item,
    required int quantity,
    required double amountPerItem,
    required double totalAmount,
  }) async {
    if (currentUser == null) throw Exception('User not authenticated');

    await expensesCollection.add({
      'pondId': pondId,
      'item': item,
      'quantity': quantity,
      'amountPerItem': amountPerItem,
      'totalAmount': totalAmount,
      'buyerId': currentUser!.uid,
      'buyerName': currentUser!.displayName ?? 'Unknown',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Deletes an expense from Firestore.
  Future<void> deleteExpense(String expenseId) async {
    if (currentUser == null) throw Exception('User not authenticated');
    await expensesCollection.doc(expenseId).delete();
  }

  /// Stream of expenses for a pond.
  Stream<QuerySnapshot<Map<String, dynamic>>> getExpensesStream(String pondId) {
    return expensesCollection
        .where('pondId', isEqualTo: pondId)
        .snapshots();
  }

  // ─── Direct Pond Expenses CRUD ────────────────────────────────────────

  /// Adds a new direct pond expense.
  Future<void> addPondExpense({
    required String pondId,
    required String category,
    required String item,
    required double quantity,
    required String unit,
    required double amountPerUnit,
    required double totalAmount,
    String notes = '',
  }) async {
    if (currentUser == null) throw Exception('User not authenticated');

    await pondExpensesCollection.add({
      'pondId': pondId,
      'category': category,
      'item': item,
      'quantity': quantity,
      'unit': unit,
      'amountPerUnit': amountPerUnit,
      'totalAmount': totalAmount,
      'recordedById': currentUser!.uid,
      'recordedByName': currentUser!.displayName ?? 'Unknown',
      'timestamp': FieldValue.serverTimestamp(),
      'notes': notes,
    });
  }

  /// Deletes a direct pond expense.
  Future<void> deletePondExpense(String expenseId) async {
    if (currentUser == null) throw Exception('User not authenticated');
    await pondExpensesCollection.doc(expenseId).delete();
  }

  /// Stream of direct pond expenses.
  Stream<QuerySnapshot<Map<String, dynamic>>> getPondExpensesStream(String pondId) {
    return pondExpensesCollection
        .where('pondId', isEqualTo: pondId)
        .snapshots();
  }

  // ─── Pond Sales CRUD ──────────────────────────────────────────────────

  /// Adds a new pond sale.
  Future<void> addPondSale({
    required String pondId,
    required String buyerName,
    required String productName,
    required double quantity,
    required String unit,
    required double pricePerUnit,
    required double totalAmount,
    String notes = '',
  }) async {
    if (currentUser == null) throw Exception('User not authenticated');

    await pondSalesCollection.add({
      'pondId': pondId,
      'buyerName': buyerName,
      'productName': productName,
      'quantity': quantity,
      'unit': unit,
      'pricePerUnit': pricePerUnit,
      'totalAmount': totalAmount,
      'recordedById': currentUser!.uid,
      'recordedByName': currentUser!.displayName ?? 'Unknown',
      'timestamp': FieldValue.serverTimestamp(),
      'notes': notes,
    });
  }

  /// Deletes a pond sale.
  Future<void> deletePondSale(String saleId) async {
    if (currentUser == null) throw Exception('User not authenticated');
    await pondSalesCollection.doc(saleId).delete();
  }

  /// Stream of pond sales.
  Stream<QuerySnapshot<Map<String, dynamic>>> getPondSalesStream(String pondId) {
    return pondSalesCollection
        .where('pondId', isEqualTo: pondId)
        .snapshots();
  }
}
