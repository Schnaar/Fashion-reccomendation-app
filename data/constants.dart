/// Environment variables and shared app constants.
abstract class Constants {
  static const String supabaseAnnonKey = String.fromEnvironment(
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1ka3FmYnVheWtmenVmcHNpdHRmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI1NjQ2MTMsImV4cCI6MjA1ODE0MDYxM30.wgbFWxh7-BYQfkFmh15OerywCV8jxHlhxp7CDesfgeM',
    defaultValue: '',
  );
}