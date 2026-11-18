<?php

namespace App\Services\Chabit;

use App\Models\Chabit\ChabitSetting;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class ChabitGeminiClient
{
    public const DEFAULT_MODEL = 'gemini-3.6-flash';

    public const ALLOWED_MODELS = [
        'gemini-3.6-flash',
        'gemini-3.8-flash',
    ];

    protected string $baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models';

    public static function sanitizeModel(?string $model): string
    {
        $clean = trim((string) $model);

        return in_array($clean, self::ALLOWED_MODELS, true) ? $clean : self::DEFAULT_MODEL;
    }

    public static function sanitizeApiKey(?string $key): ?string
    {
        if ($key === null) {
            return null;
        }
        // Strip leading/trailing whitespace and accidental internal line breaks/spaces from copy-paste
        $clean = preg_replace('/\s+/', '', trim($key));

        return $clean !== '' ? $clean : null;
    }

    /**
     * Execute a generateContent request against the official Google Gemini v1beta API.
     * Supports strictly gemini-3.6-flash (default) and gemini-3.8-flash.
     */
    public function generateContent(
        array $contents,
        ?string $systemInstruction = null,
        array $tools = [],
        bool $expectJson = false,
        ?string $modelOverride = null,
        ?string $apiKeyOverride = null
    ): array {
        try {
            $settings = ChabitSetting::current();
            $apiKey = self::sanitizeApiKey($apiKeyOverride) ?: self::sanitizeApiKey($settings->getEffectiveApiKey());
            $model = self::sanitizeModel($modelOverride ?: $settings->gemini_model);

            if (empty($apiKey)) {
                return [
                    'ok' => false,
                    'model' => $model,
                    'http_status' => 0,
                    'error' => 'Gemini API key is not configured. Please paste your Google AI Studio key and save.',
                ];
            }

            $payload = [
                'contents' => $contents,
                'generationConfig' => [
                    'temperature' => $expectJson ? 0.1 : 0.4,
                ],
            ];

            if ($expectJson) {
                $payload['generationConfig']['responseMimeType'] = 'application/json';
            }

            if (! empty($systemInstruction)) {
                $payload['systemInstruction'] = [
                    'parts' => [
                        ['text' => $systemInstruction],
                    ],
                ];
            }

            if (! empty($tools)) {
                $payload['tools'] = $tools;
            }

            $url = sprintf(
                '%s/%s:generateContent?key=%s',
                $this->baseUrl,
                rawurlencode($model),
                rawurlencode($apiKey)
            );

            $response = Http::timeout(25)
                ->connectTimeout(10)
                ->acceptJson()
                ->asJson()
                ->post($url, $payload);

            $status = $response->status();

            if ($response->successful()) {
                $json = $response->json();

                return [
                    'ok' => true,
                    'model' => $model,
                    'model_used' => $model,
                    'http_status' => $status,
                    'data' => $json,
                    'text' => $this->extractText($json),
                    'function_calls' => $this->extractFunctionCalls($json),
                ];
            }

            $bodyJson = $response->json();
            $googleStatus = $bodyJson['error']['status'] ?? null;
            $googleMsg = $bodyJson['error']['message'] ?? null;

            if ($googleMsg) {
                $errorDetail = $googleStatus ? "[{$googleStatus}] {$googleMsg}" : $googleMsg;
            } else {
                $rawBody = trim(mb_substr((string) $response->body(), 0, 400));
                $errorDetail = $rawBody !== '' ? $rawBody : 'Empty error response from Google Gemini API.';
            }

            Log::warning("ChabitGeminiClient HTTP {$status} for model {$model}: {$errorDetail}");

            return [
                'ok' => false,
                'model' => $model,
                'http_status' => $status,
                'error' => $errorDetail,
            ];
        } catch (\Illuminate\Http\Client\ConnectionException $e) {
            Log::error('ChabitGeminiClient cURL/Connection error: '.$e->getMessage());

            return [
                'ok' => false,
                'model' => self::sanitizeModel($modelOverride),
                'http_status' => 0,
                'error' => 'Network / cURL connection error: '.$e->getMessage(),
            ];
        } catch (\Throwable $e) {
            Log::error('ChabitGeminiClient exception: '.$e->getMessage());

            return [
                'ok' => false,
                'model' => self::sanitizeModel($modelOverride),
                'http_status' => 0,
                'error' => 'Unexpected client error: '.$e->getMessage(),
            ];
        }
    }

    /**
     * Test connectivity to Gemini API with the configured or provided key/model.
     */
    public function testConnection(?string $apiKey = null, ?string $model = null): array
    {
        try {
            $settings = ChabitSetting::current();
            $targetModel = self::sanitizeModel($model ?: $settings->gemini_model);
            $cleanKey = self::sanitizeApiKey($apiKey);

            $res = $this->generateContent(
                contents: [
                    [
                        'role' => 'user',
                        'parts' => [
                            ['text' => 'Reply strictly with: OK'],
                        ],
                    ],
                ],
                modelOverride: $targetModel,
                apiKeyOverride: $cleanKey
            );

            if ($res['ok']) {
                return [
                    'ok' => true,
                    'model' => $res['model_used'] ?? $targetModel,
                    'http_status' => $res['http_status'] ?? 200,
                    'reply' => trim($res['text'] ?? 'OK'),
                ];
            }

            return [
                'ok' => false,
                'model' => $res['model'] ?? $targetModel,
                'http_status' => $res['http_status'] ?? 0,
                'error' => $res['error'] ?? 'Connection failed.',
            ];
        } catch (\Throwable $e) {
            return [
                'ok' => false,
                'model' => self::sanitizeModel($model),
                'http_status' => 0,
                'error' => $e->getMessage(),
            ];
        }
    }

    public function extractText(?array $json): string
    {
        $parts = $json['candidates'][0]['content']['parts'] ?? [];
        $chunks = [];
        foreach ($parts as $part) {
            if (isset($part['text']) && is_string($part['text'])) {
                $chunks[] = $part['text'];
            }
        }

        return trim(implode("\n", $chunks));
    }

    public function extractFunctionCalls(?array $json): array
    {
        $parts = $json['candidates'][0]['content']['parts'] ?? [];
        $calls = [];
        foreach ($parts as $part) {
            if (isset($part['functionCall']) && is_array($part['functionCall'])) {
                $calls[] = $part['functionCall'];
            }
        }

        return $calls;
    }
}
