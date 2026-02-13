# SPEZIFIKATIONSENTWURF: Optimierung des Voice Interface

**Datum:** 2026-02-11 16:34 GMT+1  
**Autor:** SpecForge AI Skill  
**Version:** 1.0

---

## 1. Einleitung
Ziel dieses Dokuments ist es, ein detailliertes Pflichtenheft zur Optimierung des bestehenden Voice Interface zu erstellen. Der Fokus liegt dabei auf der Automatisierung des Audio-Recording-Stops nach Nutzereingabe und der Gewährleistung, dass stets genau eine Antwort generiert wird. Die Spezifikation gliedert sich in drei Phasen:

- **Phase 1: Gap Analysis**  
- **Phase 2: Architektur-Blueprint**  
- **Phase 3: Production-Ready Spec**


## 2. Phase 1: Gap Analysis
Analyse der aktuellen Implementierung, Identifikation von Schwachstellen und Verbesserungspotenzialen.

### 2.1 Recording-Stop-Trigger

| Status Quo | Schwachstellen | Verbesserungsbedarf |
|------------|---------------|---------------------|
| Manuelles Stoppen per Klick oder Timeout | Unzuverlässige Erkennung des Eingabeendes, Overruns oder vorzeitiges Abschneiden | Automatische Stop-Trigger auf Grundlage von SpeechDetection oder Silence-Detection implementieren |

**Schlüsselprobleme:**

1. **Timeout-Abhängigkeit** führt zu unnötiger Wartezeit, wenn Pause länger als konfiguriert.
2. **Sprachverlust** bei abruptem Cut-off, wenn Silence-Algorithmus zu aggressiv eingestellt ist.
3. **Fehlende Feedback-Schleife** für Nutzer, was gerade erkannt wird (Audio aktiv / beendet).


### 2.2 Ein-Antwort-Output
Aktuell können mehrere Antworten oder Teilantworten generiert werden.

| Status Quo | Schwachstellen | Verbesserungsbedarf |
|------------|---------------|---------------------|
| Streaming-Output oder mehrteilige Antworten | Antwortfragmentierung, Unsicherheit beim Nutzer, welches Ende der Antwort darstellt | Antwort-Pipeline auf Single-Burst-Mode umstellen: komplette Antwort erst nach Generierung liefern |

**Schlüsselprobleme:**

1. **Fragmentierte Auslieferung** führt zu schlechter UX.
2. **Ressourcenverbrauch** durch unnötiges Offenhalten der Kanalverbindung.
3. **Fehlende Konsistenz** zwischen verschiedenen Plattformen.


### 2.3 UX-Flow
Der Nutzerfluss ist nicht durchgängig klar und intuitiv.

- **Onboarding**: Keine konsistente Visualisierung des Aufnahmezustands.
- **Error-Handling**: Fehlermeldungen bei Störungen der Aufnahme sind technisch, nicht benutzerfreundlich.
- **Session Management**: Keine klare Trennung von Anfragen und Antworten bei aufeinanderfolgenden Voice-Interaktionen.

**Empfohlene Maßnahmen:**

- Einheitliche UI-Indikatoren (LED, Spinner, Mikro-Symbol mit Statuswechsel).
- Dialogbasierte Fehlermeldungen und Retry-Mechanismen.
- Session-Tokens oder Gesprächs-IDs für sauberen Kontextwechsel.


## 3. Phase 2: Architektur-Blueprint
Vorschlag für eine modulare, skalierbare Architektur mit Fokus auf Recording-Stop und Single-Response.

### 3.1 Framework- und Bibliotheksoptionen

| Modul | Option A | Option B | Bewertung |
|-------|----------|----------|-----------|
| Audio-Capture | Web Audio API (AudioWorklet, ScriptProcessor) | Recorder.js / MediaRecorder API | Web Audio API für feinkörnige Analyse, MediaRecorder für einfache Integration |
| Speech-to-Text | Web Speech API (SpeechRecognition) | Third-Party (Google, Azure) | Web Speech API schnell prototypbar, Third-Party robuster/Sprachmodelle multisprachig |
| Silence-Detection | Meyda, DSP-Lib | Eigenentwicklung (AudioContext Analyse) | Meyda für schnelle Signalverarbeitung, Eigenentwicklung für vollständige Kontrolle |


### 3.2 Event-Handling und State Management

- **State Machine** (z.B. XState) für definierte Zustände: `idle` → `listening` → `processing` → `responding` → `idle`
- **Event Bus** (z.B. RxJS, EventEmitter) zum Entkoppeln der UI-Komponenten von der Audio-Engine
- **Middleware** zur Logging/Auditing aller State-Transitions und Errors


### 3.3 Architekturdiagramm (Skizze)
```
+-------------+      +----------------+      +---------------+
|   UI/UX     | <--> | Controller/API | <--> | Audio Engine  |
+-------------+      +----------------+      +---------------+
                                          |-- SilenceDetector
                                          |-- SpeechRecognizer
                                          |-- StopTriggerModule
```


## 4. Phase 3: Production-Ready Spec
Konkrete Anforderungen, Akzeptanzkriterien, API-Spezifikation, Fehlerbehandlung, Tests und Performance.

### 4.1 Fachliche Anforderungen

1. **Auto-Stop**: Aufnahme endet automatisch spätestens 300 ms nach Sprachende.
2. **Single-Response**: Immer genau eine Antwort-Message pro Anfrage.
3. **Timeout-Fallback**: Max-Aufnahmedauer: 30s, danach Abbruch mit erklärender Fehlermeldung.
4. **Multiplattform**: Unterstützung Web (Browser) und Mobile (React Native / Cordova).


### 4.2 Akzeptanzkriterien

| Kriterium | Test | Erfolgsbedingung |
|-----------|------|------------------|
| Auto-Stop nach Sprachende | Nutzer spricht Testphrase, endet, System stoppt <500ms | Pass, wenn Stop <500ms nach letztem Audio-Peak |
| Single-Response | Simulierter Stream, System liefert einmalige JSON-Antwort | Pass, wenn only one top-level response object |
| Fehlermeldung bei Timeout | Kein Input >30s | Pass, wenn UI zeigt Timeout-Error und Retry anbietet |


### 4.3 API-Spezifikation

**Endpoint:** `POST /api/voice/recognize`

**Request-Header:**
```
Content-Type: multipart/form-data
X-Session-Token: <string>
```
**Request-Body:**
- `audio`: WAV/OGG Blob
- `language`: ISO-639-1 (default: `de`)

**Response (200 OK):**
```json
{
  "sessionId": "<string>",
  "transcript": "Erkannte Textausgabe",
  "intent": { /* optional NLP-Result */ }
}
```
**Fehlercodes:**
- `400`: Ungültiges Audioformat
- `408`: Client Timeout (Recording >30s)
- `500`: Server Error / ASR-Ausfall


### 4.4 Fehlerbehandlung

- **Clientseitig**: Validierung vor Upload (Format, Grösse), visuelles Feedback bei Fehlern.
- **Serverseitig**: Retry-Mechanismus für temporäre ASR-Ausfälle, Circuit-Breaker nach 3 Fehlversuchen.
- **Logging**: Vollständiges Error-Logging (Zeitstempel, SessionID, Stacktraces)


### 4.5 Testfälle

1. **Functional Tests**:
   - Aufnahme-Stopp nach Sprachende
   - Antwort enthält kein Partial-Chunking
   - Fehlermeldung bei No-Speech
2. **Integration Tests**:
   - End-to-End mit Browser-UI & Mock-API
   - Belastungstest mit 100 gleichzeitigen Sessions
3. **Usability Tests**:
   - Nutzerstudie: Wahrnehmung der Reaktionszeit und UX-Cues


### 4.6 Performance-Vorgaben

| Kennzahl | Zielwert |
|----------|----------|
| Latenz (Stopp bis Erstantwort) | < 1s |
| ASR-Fehlerquote | < 5 % |
| CPU-Last (Client) | < 10 % (Desktop), < 15 % (Mobile) |
| Memory-Footprint (Client) | < 50 MB |


---

*Ende des Spezifikationsentwurfs*