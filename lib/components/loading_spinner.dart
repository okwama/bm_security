import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

/// A reusable loading spinner widget with iOS-style design
/// that can be used throughout the app for consistent loading states.
class LoadingSpinner extends StatelessWidget {
  /// The message to display below the spinner
  final String? message;
  
  /// The size of the spinner (defaults to 16)
  final double size;
  
  /// The color of the spinner (uses theme color if not specified)
  final Color? color;
  
  /// Whether to show the spinner in a card/container
  final bool showInCard;
  
  /// The padding around the spinner content
  final EdgeInsets padding;
  
  /// Whether to center the spinner (useful for full-screen loading)
  final bool centered;
  
  /// The style of the loading text
  final TextStyle? textStyle;
  
  /// The spacing between spinner and text
  final double spacing;

  const LoadingSpinner({
    super.key,
    this.message,
    this.size = 16,
    this.color,
    this.showInCard = false,
    this.padding = const EdgeInsets.all(32),
    this.centered = true,
    this.textStyle,
    this.spacing = 20,
  });

  /// Factory constructor for a full-screen loading overlay
  const LoadingSpinner.fullScreen({
    super.key,
    String? message,
    double size = 20,
    Color? color,
  }) : 
    message = message ?? 'Loading...',
    size = size,
    color = color,
    showInCard = true,
    padding = const EdgeInsets.all(40),
    centered = true,
    textStyle = null,
    spacing = 24;

  /// Factory constructor for inline loading (smaller, no centering)
  const LoadingSpinner.inline({
    super.key,
    String? message,
    double size = 14,
    Color? color,
  }) : 
    message = message,
    size = size,
    color = color,
    showInCard = false,
    padding = const EdgeInsets.all(16),
    centered = false,
    textStyle = null,
    spacing = 12;

  /// Factory constructor for button loading state
  const LoadingSpinner.button({
    super.key,
    String? message,
    double size = 12,
    Color? color,
  }) : 
    message = message,
    size = size,
    color = color,
    showInCard = false,
    padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    centered = false,
    textStyle = null,
    spacing = 8;

  /// Factory constructor for card-style loading
  const LoadingSpinner.card({
    super.key,
    String? message,
    double size = 16,
    Color? color,
  }) : 
    message = message ?? 'Loading...',
    size = size,
    color = color,
    showInCard = true,
    padding = const EdgeInsets.all(24),
    centered = true,
    textStyle = null,
    spacing = 16;

  @override
  Widget build(BuildContext context) {
    final spinner = _buildSpinner(context);
    
    if (showInCard) {
      return _buildCardContainer(context, spinner);
    }
    
    if (centered) {
      return Center(child: spinner);
    }
    
    return spinner;
  }

  Widget _buildSpinner(BuildContext context) {
    final effectiveColor = color ?? CupertinoColors.systemBlue;
    final effectiveTextStyle = textStyle ?? TextStyle(
      color: CupertinoColors.secondaryLabel,
      fontSize: _getTextSize(),
      fontWeight: FontWeight.w400,
    );

    return Container(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CupertinoActivityIndicator(
            radius: size,
            color: effectiveColor,
          ),
          if (message != null) ...[
            SizedBox(height: spacing),
            Text(
              message!,
              style: effectiveTextStyle,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCardContainer(BuildContext context, Widget child) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  double _getTextSize() {
    if (size <= 12) return 12;
    if (size <= 16) return 14;
    if (size <= 20) return 16;
    return 18;
  }
}

/// A loading overlay that can be shown over existing content
class LoadingOverlay extends StatelessWidget {
  /// The child widget to show the overlay over
  final Widget child;
  
  /// Whether to show the loading overlay
  final bool isLoading;
  
  /// The loading message
  final String? message;
  
  /// The background color of the overlay
  final Color? backgroundColor;
  
  /// The loading spinner configuration
  final LoadingSpinner? loadingWidget;

  const LoadingOverlay({
    super.key,
    required this.child,
    required this.isLoading,
    this.message,
    this.backgroundColor,
    this.loadingWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: backgroundColor ?? 
                   CupertinoColors.systemBackground.withOpacity(0.8),
            child: loadingWidget ?? 
                   LoadingSpinner.fullScreen(message: message),
          ),
      ],
    );
  }
}

/// A stateful widget that provides easy loading state management
class LoadingStateBuilder extends StatefulWidget {
  /// Builder function that receives the loading state and setState function
  final Widget Function(BuildContext context, bool isLoading, Function(bool) setLoading) builder;
  
  /// Initial loading state
  final bool initialLoading;

  const LoadingStateBuilder({
    super.key,
    required this.builder,
    this.initialLoading = false,
  });

  @override
  State<LoadingStateBuilder> createState() => _LoadingStateBuilderState();
}

class _LoadingStateBuilderState extends State<LoadingStateBuilder> {
  late bool _isLoading;

  @override
  void initState() {
    super.initState();
    _isLoading = widget.initialLoading;
  }

  void _setLoading(bool loading) {
    if (mounted) {
      setState(() {
        _isLoading = loading;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _isLoading, _setLoading);
  }
}

/// Extension methods for easy loading state management
extension LoadingExtensions on Widget {
  /// Wraps this widget with a loading overlay
  Widget withLoadingOverlay({
    required bool isLoading,
    String? message,
    Color? backgroundColor,
    LoadingSpinner? loadingWidget,
  }) {
    return LoadingOverlay(
      isLoading: isLoading,
      message: message,
      backgroundColor: backgroundColor,
      loadingWidget: loadingWidget,
      child: this,
    );
  }
}

/// Usage Examples:
/// 
/// // Basic loading spinner
/// LoadingSpinner(message: 'Loading data...')
/// 
/// // Full screen loading
/// LoadingSpinner.fullScreen(message: 'Please wait...')
/// 
/// // Inline loading (smaller, no centering)
/// LoadingSpinner.inline(message: 'Refreshing...')
/// 
/// // Button loading state
/// LoadingSpinner.button()
/// 
/// // Card-style loading
/// LoadingSpinner.card(message: 'Processing...')
/// 
/// // Loading overlay
/// LoadingOverlay(
///   isLoading: _isLoading,
///   message: 'Saving changes...',
///   child: YourContentWidget(),
/// )
/// 
/// // Using extension method
/// YourWidget().withLoadingOverlay(
///   isLoading: _isLoading,
///   message: 'Loading...',
/// )
/// 
/// // Loading state builder
/// LoadingStateBuilder(
///   builder: (context, isLoading, setLoading) {
///     return Column(
///       children: [
///         if (isLoading) LoadingSpinner.inline(),
///         ElevatedButton(
///           onPressed: () async {
///             setLoading(true);
///             await someAsyncOperation();
///             setLoading(false);
///           },
///           child: Text('Load Data'),
///         ),
///       ],
///     );
///   },
/// )