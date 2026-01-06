<?php
/**
 * Szybka Fucha - Newsletter Subscribe API
 * 
 * Endpoint: POST /api/subscribe.php
 * 
 * Accepts JSON:
 * {
 *   "name": "Jan Kowalski",
 *   "email": "jan@example.com",
 *   "userType": "client" | "contractor",
 *   "consent": true,
 *   "source": "landing_page"
 * }
 */

// Load configuration
require_once __DIR__ . '/config.php';

// Set headers
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: ' . ALLOWED_ORIGIN);
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Only allow POST requests
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode([
        'success' => false,
        'message' => 'Metoda niedozwolona. Użyj POST.'
    ]);
    exit();
}

// Get JSON input
$input = file_get_contents('php://input');
$data = json_decode($input, true);

// Validate JSON
if ($data === null) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Nieprawidłowy format JSON.'
    ]);
    exit();
}

// Validate required fields
$errors = [];

// Name validation
if (empty($data['name']) || strlen(trim($data['name'])) < 2) {
    $errors[] = 'Proszę podać imię i nazwisko (min. 2 znaki).';
}

// Email validation
if (empty($data['email']) || !filter_var($data['email'], FILTER_VALIDATE_EMAIL)) {
    $errors[] = 'Proszę podać poprawny adres e-mail.';
}

// UserType validation
$allowedTypes = ['client', 'contractor'];
if (empty($data['userType']) || !in_array($data['userType'], $allowedTypes)) {
    $errors[] = 'Proszę wybrać typ użytkownika (client lub contractor).';
}

// Consent validation
if (!isset($data['consent']) || $data['consent'] !== true) {
    $errors[] = 'Wymagana jest zgoda na przetwarzanie danych.';
}

// Return validation errors
if (!empty($errors)) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => implode(' ', $errors),
        'errors' => $errors
    ]);
    exit();
}

// Sanitize input
$name = trim(htmlspecialchars($data['name'], ENT_QUOTES, 'UTF-8'));
$email = strtolower(trim($data['email']));
$userType = $data['userType'];
$source = isset($data['source']) ? trim(htmlspecialchars($data['source'], ENT_QUOTES, 'UTF-8')) : 'landing_page';

try {
    // Connect to database
    $pdo = new PDO(
        "mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4",
        DB_USER,
        DB_PASS,
        [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES => false
        ]
    );

    // Check if email already exists
    $stmt = $pdo->prepare("SELECT id, is_active FROM newsletter_subscribers WHERE email = ?");
    $stmt->execute([$email]);
    $existing = $stmt->fetch();

    if ($existing) {
        // Email exists
        if ($existing['is_active']) {
            // Already subscribed and active
            http_response_code(200);
            echo json_encode([
                'success' => true,
                'message' => 'Już jesteś zapisany do newslettera!'
            ]);
        } else {
            // Was unsubscribed, reactivate
            $stmt = $pdo->prepare("
                UPDATE newsletter_subscribers 
                SET is_active = TRUE, 
                    name = ?,
                    user_type = ?,
                    source = ?,
                    unsubscribed_at = NULL,
                    updated_at = CURRENT_TIMESTAMP
                WHERE email = ?
            ");
            $stmt->execute([$name, $userType, $source, $email]);
            
            http_response_code(200);
            echo json_encode([
                'success' => true,
                'message' => 'Dziękujemy za ponowne zapisanie się do newslettera!'
            ]);
        }
    } else {
        // New subscriber - insert
        $stmt = $pdo->prepare("
            INSERT INTO newsletter_subscribers 
            (name, email, user_type, consent, source, is_active, subscribed_at) 
            VALUES (?, ?, ?, TRUE, ?, TRUE, CURRENT_TIMESTAMP)
        ");
        $stmt->execute([$name, $email, $userType, $source]);

        http_response_code(200);
        echo json_encode([
            'success' => true,
            'message' => 'Dziękujemy za zapisanie się do newslettera!'
        ]);
    }

} catch (PDOException $e) {
    // Log error (don't expose details to user)
    error_log("Newsletter API Error: " . $e->getMessage());
    
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Wystąpił błąd serwera. Spróbuj ponownie później.'
    ]);
}
