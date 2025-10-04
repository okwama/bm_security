import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../bloc/cash_count_bloc.dart';
import '../widgets/denomination_grid.dart';
import '../widgets/total_header.dart';
import '../widgets/submit_button.dart';
import '../../domain/entities/cash_count_entity.dart';

class CashCountPage extends StatefulWidget {
  final int requestId;
  final int staffId;
  final bool isAtmCashCount;
  final Function(dynamic)? onConfirm;

  const CashCountPage({
    super.key,
    required this.requestId,
    required this.staffId,
    required this.isAtmCashCount,
    this.onConfirm,
  });

  @override
  State<CashCountPage> createState() => _CashCountPageState();
}

class _CashCountPageState extends State<CashCountPage> {
  final _formKey = GlobalKey<FormState>();
  String? _sealNumber;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isAtmCashCount ? 'ATM Cash Count' : 'Cash Count'),
        backgroundColor: const Color(AppConstants.primaryColorValue),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              context.read<CashCountBloc>().add(const ClearCashCountEvent());
            },
          ),
        ],
      ),
      body: BlocListener<CashCountBloc, CashCountState>(
        listener: (context, state) {
          if (state is CashCountSubmitted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cash count submitted successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            if (widget.onConfirm != null) {
              widget.onConfirm!(state.cashCount);
            }
            Navigator.pop(context, state.cashCount);
          } else if (state is CashCountError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Total Header
              BlocBuilder<CashCountBloc, CashCountState>(
                builder: (context, state) {
                  if (state is CashCountInitial) {
                    return TotalHeader(
                      total: state.denominations.totalAmount,
                      filledCount: state.denominations.filledCount,
                    );
                  }
                  return const TotalHeader(total: 0, filledCount: 0);
                },
              ),

              // Denomination Grid
              Expanded(
                child: BlocBuilder<CashCountBloc, CashCountState>(
                  builder: (context, state) {
                    if (state is CashCountInitial) {
                      return DenominationGrid(
                        denominations: state.denominations,
                        onDenominationChanged: (denomination, value) {
                          context.read<CashCountBloc>().add(
                            UpdateDenominationEvent(
                              denomination: denomination,
                              value: value,
                            ),
                          );
                        },
                      );
                    }
                    return const Center(child: CircularProgressIndicator());
                  },
                ),
              ),

              // Seal Number Input (if not ATM)
              if (!widget.isAtmCashCount) ...[
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Seal Number (Optional)',
                      prefixIcon: Icon(Icons.security),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      _sealNumber = value;
                    },
                  ),
                ),
              ],

              // Submit Button
              BlocBuilder<CashCountBloc, CashCountState>(
                builder: (context, state) {
                  return SubmitButton(
                    isLoading: state is CashCountSubmitting,
                    onPressed: state is CashCountSubmitting
                        ? null
                        : () => _submitCashCount(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitCashCount() {
    if (!_formKey.currentState!.validate()) return;

    final state = context.read<CashCountBloc>().state;
    if (state is! CashCountInitial) return;

    final denominations = state.denominations;

    // Check if at least one denomination is filled
    if (denominations.totalAmount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter at least one denomination'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // If onConfirm is null, just return the data without saving
    if (widget.onConfirm == null) {
      // Create a CashCountEntity with the current denominations
      final cashCount = CashCountEntity(
        id: 0, // Temporary ID
        requestId: widget.requestId,
        staffId: widget.staffId,
        ones: denominations.ones,
        fives: denominations.fives,
        tens: denominations.tens,
        twenties: denominations.twenties,
        forties: denominations.forties,
        fifties: denominations.fifties,
        hundreds: denominations.hundreds,
        twoHundreds: denominations.twoHundreds,
        fiveHundreds: denominations.fiveHundreds,
        thousands: denominations.thousands,
        totalAmount: denominations.totalAmount,
        sealNumber: _sealNumber,
        imagePath: null,
        imageUrl: null,
        status: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cash count data ready. Will be saved on pickup confirmation.'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );
      
      Navigator.pop(context, cashCount);
      return;
    }

    // If onConfirm is provided, save to server
    context.read<CashCountBloc>().add(
      SubmitCashCountEvent(
        requestId: widget.requestId,
        staffId: widget.staffId,
        ones: denominations.ones,
        fives: denominations.fives,
        tens: denominations.tens,
        twenties: denominations.twenties,
        forties: denominations.forties,
        fifties: denominations.fifties,
        hundreds: denominations.hundreds,
        twoHundreds: denominations.twoHundreds,
        fiveHundreds: denominations.fiveHundreds,
        thousands: denominations.thousands,
        sealNumber: _sealNumber,
        isAtmCashCount: widget.isAtmCashCount,
      ),
    );
  }
}
