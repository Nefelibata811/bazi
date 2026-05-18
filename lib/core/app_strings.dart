/// 全应用统一文案，避免同一场景多种说法。
abstract final class AppStrings {
  // —— 登录 ——
  static const loginRequired = '请先登录';
  static const loginRequiredForAi = '请先登录后再使用 AI 看盘';
  static const loginRequiredForChart = '请先登录并完成排盘';

  // —— 排盘 / 保存 ——
  static const chartCreatedLoggedIn = '排盘保存成功';
  static const chartCreatedGuest =
      '排盘成功（登录后可云端保存并用于 AI 看盘）';
  static const chartSaveCloudFailed =
      '排盘已生成，但云端保存失败，请检查网络后重试';
  static const chartSaveFailed = '保存失败，请稍后重试';
  static const chartSaveFailedRetry = '保存失败，请检查网络后重试';
  static const noChartData = '暂无排盘数据';

  // —— AI 看盘 ——
  static const aiSelectChartTitle = '选择一份排盘';
  static const aiNoSavedRecords = '暂无排盘记录，请先在主页排盘并保存';
  static const aiPickChartPrompt = '请选择一份排盘';
  static const aiPickChartSubtitle =
      '请先在主页完成排盘并保存，再在此选择命盘进行分析';
  static const aiEmptyNoChat = '暂无对话记录';
  static const aiEmptyNoChatSubtitle =
      '点击下方按钮，AI 将根据所选命盘生成命理分析';
  static const aiPickChartToStart = '选择已保存的排盘';
  static const aiAnalyzing = '正在生成命理分析…';
  static const aiAnalyzingHint =
      '分析进行中，可点击停止取消；切换或取消命盘将中断当前分析';
  static const aiHistoryRestored = '已恢复历史对话，可直接继续追问';
  static const chartLoading = '命盘加载中…';
  static const chartSwitching = '正在切换命盘…';
  static const chartListLoading = '命盘列表加载中…';
  static const chartListRefreshing = '正在同步最新命盘…';
  static const chartListLoadFailed = '命盘列表加载失败，请检查网络';

  // —— 操作语义（勿混用）——
  static const actionDeleteChat = '删除对话';
  static const actionDeleteChatTitle = '删除对话记录';
  static const actionDeleteChatBody =
      '将清除该命盘下的全部 AI 对话，此操作不可恢复。';
  static const actionClearChart = '取消当前命盘';
  static const actionChatDeleted = '对话记录已删除';

  static const actionCancel = '取消';
  static const actionCancelAnalysis = '取消分析';
  static const analysisCancelled = '已取消分析';
  static const actionDelete = '删除';
  static const actionRetry = '重试';
  static const actionGenerateAnalysis = '生成命理分析';
}
