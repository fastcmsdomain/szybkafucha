<?php
/**
 * Check Newsletter Subscriber API
 *
 * Endpoint: GET /api/check-subscriber.php?email=user@example.com
 *
 * Returns subscriber data if exists in newsletter database
 * Used by NestJS backend during user registration
 */

require_once __DIR__ . '/config.php';

// Set headers
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *'); // Allow NestJS backend to call this
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Only allow GET requests
if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode([
        'success' => false,
        'message' => 'Method not allowed. Use GET.'
    ]);
    exit();
}

// Get email parameter
$email = isset($_GET['email']) ? trim($_GET['email']) : '';

// Validate email
if (empty($email) || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Invalid email address.'
    ]);
    exit();
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

    // Check if subscriber exists and is active
    $stmt = $pdo->prepare("
        SELECT
            name,
            email,
            user_type,
            city,
            services,
            comments,
            subscribed_at
        FROM newsletter_subscribers
        WHERE email = ? AND is_active = TRUE
    ");
    $stmt->execute([strtolower($email)]);
    $subscriber = $stmt->fetch();

    if ($subscriber) {
        // Parse services JSON if exists
        if (!empty($subscriber['services'])) {
            $subscriber['services'] = json_decode($subscriber['services'], true);
        }

        http_response_code(200);
        echo json_encode([
            'success' => true,
            'found' => true,
            'data' => $subscriber
        ]);
    } else {
        // Not found or not active
        http_response_code(200);
        echo json_encode([
            'success' => true,
            'found' => false,
            'data' => null
        ]);
    }

} catch (PDOException $e) {
    error_log("Check Subscriber API Error: " . $e->getMessage());

    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Internal server error.'
    ]);
}
