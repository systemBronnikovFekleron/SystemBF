<?php
/**
 * API Client for Rails platform
 *
 * @package BronnikovSSO
 */

// Exit if accessed directly.
if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

/**
 * Class Bronnikov_API
 */
class Bronnikov_API {

    /**
     * API base URL
     *
     * @var string
     */
    private $api_url;

    /**
     * Constructor
     */
    public function __construct() {
        $settings = get_option( 'bronnikov_sso_settings', array() );
        $this->api_url = isset( $settings['api_url'] )
            ? trailingslashit( $settings['api_url'] )
            : 'https://platform.bronnikov.com/';
    }

    /**
     * Validate JWT token with Rails API
     *
     * @param string $token JWT token from cookie.
     * @return array|false User data array or false on failure.
     */
    public function validate_token( $token ) {
        if ( empty( $token ) ) {
            return false;
        }

        $url = $this->api_url . 'api/v1/validate_token';

        $response = wp_remote_get( $url, array(
            'headers' => array(
                'Authorization' => 'Bearer ' . $token,
                'Content-Type'  => 'application/json',
            ),
            'timeout' => 10,
        ) );

        // Check for errors.
        if ( is_wp_error( $response ) ) {
            error_log( 'Bronnikov SSO API Error: ' . $response->get_error_message() );
            return false;
        }

        $status_code = wp_remote_retrieve_response_code( $response );
        if ( 200 !== $status_code ) {
            return false;
        }

        $body = wp_remote_retrieve_body( $response );
        $data = json_decode( $body, true );

        // Validate response structure.
        if ( ! isset( $data['valid'] ) || ! $data['valid'] ) {
            return false;
        }

        if ( ! isset( $data['user'] ) ) {
            return false;
        }

        return $data['user'];
    }

    /**
     * Test API connection
     *
     * @return bool True if connection successful.
     */
    public function test_connection() {
        $url = $this->api_url . 'up'; // Rails health check endpoint

        $response = wp_remote_get( $url, array(
            'timeout' => 5,
        ) );

        if ( is_wp_error( $response ) ) {
            return false;
        }

        $status_code = wp_remote_retrieve_response_code( $response );
        return 200 === $status_code;
    }
}
