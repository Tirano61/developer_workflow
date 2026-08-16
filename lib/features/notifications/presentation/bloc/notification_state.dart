enum NotificationStatus { initial, initializing, ready, error }

class NotificationState {
  const NotificationState({
    this.status = NotificationStatus.initial,
    this.pushSupported = true,
    this.initialized = false,
    this.permissionRequested = false,
    this.isAuthenticated = false,
    this.currentFcmToken,
    this.lastRegisteredToken,
    this.pendingDiscussionId,
    this.openDiscussionId,
    this.navigationRequestVersion = 0,
    this.lastNotificationType = '',
    this.errorMessage = '',
  });

  final NotificationStatus status;
  final bool pushSupported;
  final bool initialized;
  final bool permissionRequested;
  final bool isAuthenticated;
  final String? currentFcmToken;
  final String? lastRegisteredToken;
  final String? pendingDiscussionId;
  final String? openDiscussionId;
  final int navigationRequestVersion;
  final String lastNotificationType;
  final String errorMessage;

  NotificationState copyWith({
    NotificationStatus? status,
    bool? pushSupported,
    bool? initialized,
    bool? permissionRequested,
    bool? isAuthenticated,
    String? currentFcmToken,
    String? lastRegisteredToken,
    String? pendingDiscussionId,
    String? openDiscussionId,
    int? navigationRequestVersion,
    String? lastNotificationType,
    String? errorMessage,
    bool clearCurrentFcmToken = false,
    bool clearLastRegisteredToken = false,
    bool clearPendingDiscussionId = false,
    bool clearOpenDiscussionId = false,
  }) {
    return NotificationState(
      status: status ?? this.status,
      pushSupported: pushSupported ?? this.pushSupported,
      initialized: initialized ?? this.initialized,
      permissionRequested: permissionRequested ?? this.permissionRequested,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      currentFcmToken: clearCurrentFcmToken
          ? null
          : currentFcmToken ?? this.currentFcmToken,
      lastRegisteredToken: clearLastRegisteredToken
          ? null
          : lastRegisteredToken ?? this.lastRegisteredToken,
      pendingDiscussionId: clearPendingDiscussionId
          ? null
          : pendingDiscussionId ?? this.pendingDiscussionId,
      openDiscussionId: clearOpenDiscussionId
          ? null
          : openDiscussionId ?? this.openDiscussionId,
      navigationRequestVersion:
          navigationRequestVersion ?? this.navigationRequestVersion,
      lastNotificationType: lastNotificationType ?? this.lastNotificationType,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
