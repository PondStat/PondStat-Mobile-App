import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pondstat/core/firebase/firebase_providers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pondstat/core/services/connectivity_provider.dart';
import 'package:pondstat/core/firebase/offline_repository_mixin.dart';

part 'finances_repository.g.dart';

@riverpod
FinancesRepository financesRepository(Ref ref) {
  final baseRef = ref.watch(appBaseRefProvider);
  final auth = ref.watch(firebaseAuthProvider);
  final isOffline = ref.watch(isOfflineProvider);
  return FinancesRepository(
    baseRef,
    auth,
    isOffline: () => isOffline,
  );
}

class FinancesRepository with OfflineRepositoryMixin {
  final DocumentReference<Map<String, dynamic>> _baseRef;
  final FirebaseAuth _auth;
  @override
  final bool Function() isOffline;

  FinancesRepository(
    this._baseRef,
    this._auth, {
    required this.isOffline,
  });

  User? get currentUser => _auth.currentUser;

  // ─── Collection References ───────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> get expensesCollection =>
      _baseRef.collection('expenses');

  CollectionReference<Map<String, dynamic>> get pondExpensesCollection =>
      _baseRef.collection('pond_expenses');

  CollectionReference<Map<String, dynamic>> get pondSalesCollection =>
      _baseRef.collection('pond_sales');

  CollectionReference<Map<String, dynamic>> get measurementHistoryCollection =>
      _baseRef.collection('measurement_history');

  void _logHistory({
    required String pondId,
    required String action,
    required String itemType,
    required Map<String, dynamic>? before,
    required Map<String, dynamic>? after,
  }) {
    if (currentUser == null) return;
    measurementHistoryCollection.add({
      'pondId': pondId,
      'parameter': itemType,
      'action': action,
      'editedAt': FieldValue.serverTimestamp(),
      'editedBy': currentUser!.uid,
      'editorName': currentUser!.displayName ?? 'Unknown',
      'before': before,
      'after': after,
    });
  }

  void _validatePositive(String fieldName, num value) {
    if (value <= 0) {
      throw ArgumentError('$fieldName must be greater than 0');
    }
  }

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
    _validatePositive('Quantity', quantity);
    _validatePositive('Amount per item', amountPerItem);

    final verifiedTotalAmount = double.parse((quantity * amountPerItem).toStringAsFixed(2));

    await runWrite(() async {
      await expensesCollection.add({
        'pondId': pondId,
        'item': item,
        'quantity': quantity,
        'amountPerItem': amountPerItem,
        'totalAmount': verifiedTotalAmount,
        'buyerId': currentUser!.uid,
        'buyerName': currentUser!.displayName ?? 'Unknown',
        'timestamp': FieldValue.serverTimestamp(),
      });

      _logHistory(
        pondId: pondId,
        action: 'create',
        itemType: 'Group Expense',
        before: null,
        after: {'value': '\$$verifiedTotalAmount ($item, qty: $quantity)'},
      );
    });
  }

  /// Deletes an expense from Firestore.
  Future<void> deleteExpense(String expenseId) async {
    if (currentUser == null) throw Exception('User not authenticated');
    
    // Fetch document details before deleting for history logging
    final source = isOffline() ? Source.cache : Source.serverAndCache;
    try {
      final doc = await expensesCollection.doc(expenseId).get(GetOptions(source: source));
      if (doc.exists) {
        final data = doc.data()!;
        final pondId = data['pondId'] as String;
        final item = data['item'] as String? ?? 'Item';
        final totalAmount = data['totalAmount'] as double? ?? 0.0;
        
        _logHistory(
          pondId: pondId,
          action: 'delete',
          itemType: 'Group Expense',
          before: {'value': '\$$totalAmount ($item)'},
          after: null,
        );
      }
    } catch (_) {}

    await runWrite(() => expensesCollection.doc(expenseId).delete());
  }

  /// Stream of expenses for a pond.
  Stream<QuerySnapshot<Map<String, dynamic>>> getExpensesStream(String pondId) {
    return expensesCollection
        .where('pondId', isEqualTo: pondId)
        .orderBy('timestamp', descending: true)
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
    _validatePositive('Quantity', quantity);
    _validatePositive('Amount per unit', amountPerUnit);

    final verifiedTotalAmount = double.parse((quantity * amountPerUnit).toStringAsFixed(2));

    await runWrite(() async {
      await pondExpensesCollection.add({
        'pondId': pondId,
        'category': category,
        'item': item,
        'quantity': quantity,
        'unit': unit,
        'amountPerUnit': amountPerUnit,
        'totalAmount': verifiedTotalAmount,
        'recordedById': currentUser!.uid,
        'recordedByName': currentUser!.displayName ?? 'Unknown',
        'timestamp': FieldValue.serverTimestamp(),
        'notes': notes,
      });

      _logHistory(
        pondId: pondId,
        action: 'create',
        itemType: 'Pond Expense',
        before: null,
        after: {'value': '\$$verifiedTotalAmount ($item, qty: $quantity $unit)'},
      );
    });
  }

  /// Deletes a direct pond expense.
  Future<void> deletePondExpense(String expenseId) async {
    if (currentUser == null) throw Exception('User not authenticated');

    final source = isOffline() ? Source.cache : Source.serverAndCache;
    try {
      final doc = await pondExpensesCollection.doc(expenseId).get(GetOptions(source: source));
      if (doc.exists) {
        final data = doc.data()!;
        final pondId = data['pondId'] as String;
        final item = data['item'] as String? ?? 'Item';
        final totalAmount = data['totalAmount'] as double? ?? 0.0;
        
        _logHistory(
          pondId: pondId,
          action: 'delete',
          itemType: 'Pond Expense',
          before: {'value': '\$$totalAmount ($item)'},
          after: null,
        );
      }
    } catch (_) {}

    await runWrite(() => pondExpensesCollection.doc(expenseId).delete());
  }

  /// Stream of direct pond expenses.
  Stream<QuerySnapshot<Map<String, dynamic>>> getPondExpensesStream(String pondId) {
    return pondExpensesCollection
        .where('pondId', isEqualTo: pondId)
        .orderBy('timestamp', descending: true)
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
    _validatePositive('Quantity', quantity);
    _validatePositive('Price per unit', pricePerUnit);

    final verifiedTotalAmount = double.parse((quantity * pricePerUnit).toStringAsFixed(2));

    await runWrite(() async {
      await pondSalesCollection.add({
        'pondId': pondId,
        'buyerName': buyerName,
        'productName': productName,
        'quantity': quantity,
        'unit': unit,
        'pricePerUnit': pricePerUnit,
        'totalAmount': verifiedTotalAmount,
        'recordedById': currentUser!.uid,
        'recordedByName': currentUser!.displayName ?? 'Unknown',
        'timestamp': FieldValue.serverTimestamp(),
        'notes': notes,
      });

      _logHistory(
        pondId: pondId,
        action: 'create',
        itemType: 'Pond Sale',
        before: null,
        after: {'value': '\$$verifiedTotalAmount ($productName to $buyerName, qty: $quantity $unit)'},
      );
    });
  }

  /// Deletes a pond sale.
  Future<void> deletePondSale(String saleId) async {
    if (currentUser == null) throw Exception('User not authenticated');

    final source = isOffline() ? Source.cache : Source.serverAndCache;
    try {
      final doc = await pondSalesCollection.doc(saleId).get(GetOptions(source: source));
      if (doc.exists) {
        final data = doc.data()!;
        final pondId = data['pondId'] as String;
        final productName = data['productName'] as String? ?? 'Product';
        final totalAmount = data['totalAmount'] as double? ?? 0.0;
        
        _logHistory(
          pondId: pondId,
          action: 'delete',
          itemType: 'Pond Sale',
          before: {'value': '\$$totalAmount ($productName)'},
          after: null,
        );
      }
    } catch (_) {}

    await runWrite(() => pondSalesCollection.doc(saleId).delete());
  }

  /// Stream of pond sales.
  Stream<QuerySnapshot<Map<String, dynamic>>> getPondSalesStream(String pondId) {
    return pondSalesCollection
        .where('pondId', isEqualTo: pondId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}
