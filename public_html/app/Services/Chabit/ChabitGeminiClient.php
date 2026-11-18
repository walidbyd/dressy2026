<?php

namespace App\Services\Chabit;

use App\Models\Chabit\ChabitSetting;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class ChabitGeminiClient
{
    protected string $baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models';

    /**
     * Execute a generateContent request against Google Gemini API.
     */
    public function generateContent(
        array $contents,
        ?string $systemInstruction = null,
        array $tools = [],
        bool $expectJson = false,
        ?string $modelOverride = null,
        ?string $apiKeyOverride = null
    ): array {
        $settings = ChabitSetting::current();
        $apiKey = $apiKeyOverride ?: $settings->getEffectiveApiKey();
        $model = $modelOverride ?: ($settings->gemini_model ?: 'gemini-3.6-flash');

        if (empty($apiKey)) {
            return [
                'ok' => false,
                'error' => 'Gemini API key is not configured.',
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

        $modelsToTry = array_values(array_unique([$model, 'gemini-2.5-flash']));
        $lastError = 'Unknown Gemini API error';

        foreach ($modelsToTry as $idx => $candidateModel) {
            try {
                $url = sprintf('%s/%s:generateContent?key=%s', $this->baseUrl, urlencode($candidateModel), urlencode($apiKey));
                $response = Http::timeout(25)
                    ->acceptJson()
                    ->asJson()
                    ->post($url, $payload);

                if ($response->successful()) {
                    $json = $response->json();

                    return [
                        'ok' => true,
                        'model_used' => $candidateModel,
                        'data' => $json,
                        'text' => $this->extractText($json),
                        'function_calls' => $this->extractFunctionCalls($json),
                    ];
                }

                $status = $response->status();
                $body = $response->json();
                $lastError = $body['error']['message'] ?? ('HTTP '.$status.': '.$response->body());

                // Only fallback to secondary model if model-not-found (404) and this wasn't an explicit test
                if ($status === 404 && $idx === 0 && empty($modelOverride)) {
                    Log::warning("Chabit Gemini model '{$candidateModel}' returned 404; trying fallback.");
                    continue;
                }

                return [
                    'ok' => false,
                    'status' => $status,
                    'error' => $lastError,
                ];
            } catch (\Throwable $e) {
                $lastError = $e->getMessage();
                Log::error('ChabitGeminiClient exception: '.$lastError);

                return [
                    'ok' => false,
                    'error' => $lastError,
                ];
            }
        }

        return [
            'ok' => false,
            'error' => $lastError,
        ];
    }

    /**
     * Test connectivity to Gemini API with the configured or provided key/model.
     */
    public function testConnection(?string $apiKey = null, ?string $model = null): array
    {
        $settings = ChabitSetting::current();
        $targetModel = $model ?: ($settings->gemini_model ?: 'gemini-3.6-flash');

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
            apiKeyOverride: $apiKey
        );

        if ($res['ok']) {
            return [
                'ok' => true,
                'model' => $res['model_used'] ?? $targetModel,
                'reply' => trim($res['text'] ?? 'OK'),
            ];
        }

        return [
            'ok' => false,
            'model' => $targetModel,
            'error' => $res['error'] ?? 'Connection failed',
        ];
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
