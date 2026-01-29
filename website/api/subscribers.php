<?php
/**
 * Szybka Fucha - Subscribers API
 * 
 * Endpoint: GET /api/subscribers.php
 * 
 * Returns list of all newsletter subscribers from database
 * Used by admin panel to display users
 */

// Load configuration
require_once __DIR__ . '/config.php';

// Set headers
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *'); // Allow admin panel access
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
        'message' => 'Metoda niedozwolona. Użyj GET.'
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

    // Check if new columns exist
    $columnsCheckCity = $pdo->query("SHOW COLUMNS FROM newsletter_subscribers LIKE 'city'")->fetch();
    $hasCityColumn = $columnsCheckCity !== false;

    $columnsCheck = $pdo->query("SHOW COLUMNS FROM newsletter_subscribers LIKE 'services'")->fetch();
    $hasServicesColumn = $columnsCheck !== false;

    $columnsCheckComments = $pdo->query("SHOW COLUMNS FROM newsletter_subscribers LIKE 'comments'")->fetch();
    $hasCommentsColumn = $columnsCheckComments !== false;

    // Build query based on available columns
    $selectFields = "id, name, email, user_type, consent, source, is_active, subscribed_at, unsubscribed_at, created_at, updated_at";

    if ($hasCityColumn) {
        $selectFields .= ", city";
    }
    if ($hasServicesColumn) {
        $selectFields .= ", services";
    }
    if ($hasCommentsColumn) {
        $selectFields .= ", comments";
    }

    // Get all subscribers, ordered by most recent first
    $stmt = $pdo->query("SELECT {$selectFields} FROM newsletter_subscribers ORDER BY created_at DESC");
    $subscribers = $stmt->fetchAll();

    // Transform data for frontend
    $transformedSubscribers = array_map(function($subscriber) use ($hasCityColumn, $hasServicesColumn, $hasCommentsColumn) {
        $result = [
            'id' => $subscriber['id'],
            'name' => $subscriber['name'],
            'email' => $subscriber['email'],
            'userType' => $subscriber['user_type'],
            'consent' => (bool)$subscriber['consent'],
            'source' => $subscriber['source'],
            'isActive' => (bool)$subscriber['is_active'],
            'subscribedAt' => $subscriber['subscribed_at'],
            'unsubscribedAt' => $subscriber['unsubscribed_at'],
            'createdAt' => $subscriber['created_at'],
            'updatedAt' => $subscriber['updated_at'],
        ];

        // Add city if column exists
        if ($hasCityColumn && isset($subscriber['city'])) {
            $result['city'] = $subscriber['city'] ?? null;
        } else {
            $result['city'] = null;
        }

        // Add services if column exists
        if ($hasServicesColumn && isset($subscriber['services'])) {
            $result['services'] = $subscriber['services'] ? json_decode($subscriber['services'], true) : [];
        } else {
            $result['services'] = [];
        }

        // Add comments if column exists
        if ($hasCommentsColumn && isset($subscriber['comments'])) {
            $result['comments'] = $subscriber['comments'] ?? '';
        } else {
            $result['comments'] = '';
        }

        return $result;
    }, $subscribers);

    // Get stats
    $totalCount = count($subscribers);
    $activeCount = count(array_filter($subscribers, fn($s) => $s['is_active']));
    $clientCount = count(array_filter($subscribers, fn($s) => $s['user_type'] === 'client'));
    $contractorCount = count(array_filter($subscribers, fn($s) => $s['user_type'] === 'contractor'));

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'data' => $transformedSubscribers,
        'stats' => [
            'total' => $totalCount,
            'active' => $activeCount,
            'inactive' => $totalCount - $activeCount,
            'clients' => $clientCount,
            'contractors' => $contractorCount,
        ],
        'meta' => [
            'hasCityColumn' => $hasCityColumn,
            'hasServicesColumn' => $hasServicesColumn,
            'hasCommentsColumn' => $hasCommentsColumn,
        ]
    ]);

} catch (PDOException $e) {
    // Log error (don't expose details to user)
    error_log("Subscribers API Error: " . $e->getMessage());
    
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Wystąpił błąd serwera. Spróbuj ponownie później.',
        'error' => $e->getMessage() // Remove in production
    ]);
}
