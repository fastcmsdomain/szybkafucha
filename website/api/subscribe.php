<?php
/**
 * Szybka Fucha - Formularz Ulepszeń Aplikacji API
 * 
 * Endpoint: POST /api/subscribe.php
 * 
 * Accepts JSON:
 * {
 *   "name": "Jan Kowalski",
 *   "email": "jan@example.com",
 *   "city": "Warszawa",
 *   "userType": "client" | "contractor",
 *   "consent": true,
 *   "source": "formularz_ulepszen_apki" | "landing_page_hero",
 *   "services": ["cleaning", "shopping", "repairs"],
 *   "comments": "Chciałbym mieć możliwość..."
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
$source = isset($data['source']) ? trim(htmlspecialchars($data['source'], ENT_QUOTES, 'UTF-8')) : 'formularz_ulepszen_apki';

// Handle optional city field
$city = null;
if (isset($data['city']) && !empty(trim($data['city']))) {
    $city = trim(htmlspecialchars($data['city'], ENT_QUOTES, 'UTF-8'));
}

// Handle optional fields: services (array) and comments (string)
$services = null;
if (isset($data['services']) && is_array($data['services']) && !empty($data['services'])) {
    // Validate and sanitize services array
    $allowedServices = ['cleaning', 'shopping', 'repairs', 'garden', 'pets', 'assembly', 'moving', 'queues', 'transport', 'it', 'tutoring', 'events'];
    $validServices = array_filter($data['services'], function($service) use ($allowedServices) {
        return in_array($service, $allowedServices);
    });
    if (!empty($validServices)) {
        $services = json_encode($validServices, JSON_UNESCAPED_UNICODE);
    }
}

$comments = null;
if (isset($data['comments']) && !empty(trim($data['comments']))) {
    $comments = trim(htmlspecialchars($data['comments'], ENT_QUOTES, 'UTF-8'));
    // Limit to 500 characters
    if (strlen($comments) > 500) {
        $comments = substr($comments, 0, 500);
    }
}

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
            // Already subscribed and active - update data if provided
            // Check if optional columns exist
            $columnsCheck = $pdo->query("SHOW COLUMNS FROM newsletter_subscribers LIKE 'services'")->fetch();
            $hasServicesColumn = $columnsCheck !== false;
            
            $columnsCheckComments = $pdo->query("SHOW COLUMNS FROM newsletter_subscribers LIKE 'comments'")->fetch();
            $hasCommentsColumn = $columnsCheckComments !== false;
            
            $columnsCheckCity = $pdo->query("SHOW COLUMNS FROM newsletter_subscribers LIKE 'city'")->fetch();
            $hasCityColumn = $columnsCheckCity !== false;
            
            // Build dynamic update query
            $updateFields = [];
            $updateValues = [];
            
            if ($hasCityColumn && $city !== null) {
                $updateFields[] = "city = ?";
                $updateValues[] = $city;
            }
            
            if ($hasServicesColumn && $services !== null) {
                $updateFields[] = "services = ?";
                $updateValues[] = $services;
            }
            
            if ($hasCommentsColumn && $comments !== null) {
                $updateFields[] = "comments = ?";
                $updateValues[] = $comments;
            }
            
            if (!empty($updateFields)) {
                $updateFields[] = "updated_at = CURRENT_TIMESTAMP";
                $updateValues[] = $email;
                
                $stmt = $pdo->prepare("
                    UPDATE newsletter_subscribers 
                    SET " . implode(", ", $updateFields) . "
                    WHERE email = ?
                ");
                $stmt->execute($updateValues);
            }
            
            http_response_code(200);
            echo json_encode([
                'success' => true,
                'message' => 'Dziękujemy za aktualizację danych!'
            ]);
        } else {
            // Was unsubscribed, reactivate
            // Check if optional columns exist
            $columnsCheck = $pdo->query("SHOW COLUMNS FROM newsletter_subscribers LIKE 'services'")->fetch();
            $hasServicesColumn = $columnsCheck !== false;
            
            $columnsCheckComments = $pdo->query("SHOW COLUMNS FROM newsletter_subscribers LIKE 'comments'")->fetch();
            $hasCommentsColumn = $columnsCheckComments !== false;
            
            $columnsCheckCity = $pdo->query("SHOW COLUMNS FROM newsletter_subscribers LIKE 'city'")->fetch();
            $hasCityColumn = $columnsCheckCity !== false;
            
            // Build dynamic UPDATE query
            $updateFields = [
                "is_active = TRUE",
                "name = ?",
                "user_type = ?",
                "source = ?",
            ];
            $updateValues = [$name, $userType, $source];
            
            if ($hasCityColumn) {
                $updateFields[] = "city = ?";
                $updateValues[] = $city;
            }
            
            if ($hasServicesColumn) {
                $updateFields[] = "services = ?";
                $updateValues[] = $services;
            }
            
            if ($hasCommentsColumn) {
                $updateFields[] = "comments = ?";
                $updateValues[] = $comments;
            }
            
            $updateFields[] = "unsubscribed_at = NULL";
            $updateFields[] = "updated_at = CURRENT_TIMESTAMP";
            $updateValues[] = $email;
            
            $stmt = $pdo->prepare("
                UPDATE newsletter_subscribers 
                SET " . implode(", ", $updateFields) . "
                WHERE email = ?
            ");
            $stmt->execute($updateValues);
            
            http_response_code(200);
            echo json_encode([
                'success' => true,
                'message' => 'Dziękujemy za ponowne zapisanie się do newslettera!'
            ]);
        }
    } else {
        // New subscriber - insert
        // Check if optional columns exist
        $columnsCheck = $pdo->query("SHOW COLUMNS FROM newsletter_subscribers LIKE 'services'")->fetch();
        $hasServicesColumn = $columnsCheck !== false;
        
        $columnsCheckComments = $pdo->query("SHOW COLUMNS FROM newsletter_subscribers LIKE 'comments'")->fetch();
        $hasCommentsColumn = $columnsCheckComments !== false;
        
        $columnsCheckCity = $pdo->query("SHOW COLUMNS FROM newsletter_subscribers LIKE 'city'")->fetch();
        $hasCityColumn = $columnsCheckCity !== false;
        
        // Build dynamic INSERT query based on available columns
        $columns = ['name', 'email', 'user_type', 'consent', 'source', 'is_active', 'subscribed_at'];
        $placeholders = ['?', '?', '?', 'TRUE', '?', 'TRUE', 'CURRENT_TIMESTAMP'];
        $values = [$name, $email, $userType, $source];
        
        if ($hasCityColumn) {
            $columns[] = 'city';
            $placeholders[] = '?';
            $values[] = $city;
        }
        
        if ($hasServicesColumn) {
            $columns[] = 'services';
            $placeholders[] = '?';
            $values[] = $services;
        }
        
        if ($hasCommentsColumn) {
            $columns[] = 'comments';
            $placeholders[] = '?';
            $values[] = $comments;
        }
        
        $stmt = $pdo->prepare("
            INSERT INTO newsletter_subscribers 
            (" . implode(', ', $columns) . ") 
            VALUES (" . implode(', ', $placeholders) . ")
        ");
        $stmt->execute($values);

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
