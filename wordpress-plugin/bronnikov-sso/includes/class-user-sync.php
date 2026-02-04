<?php
/**
 * User synchronization handler
 *
 * @package BronnikovSSO
 */

// Exit if accessed directly.
if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

/**
 * Class Bronnikov_User_Sync
 */
class Bronnikov_User_Sync {

    /**
     * Sync user data on WordPress login
     *
     * @param string  $user_login WordPress username.
     * @param WP_User $user WordPress user object.
     */
    public static function sync_on_login( $user_login, $user ) {
        // Get JWT token from cookie.
        $token = isset( $_COOKIE['jwt_token'] ) ? sanitize_text_field( $_COOKIE['jwt_token'] ) : null;

        if ( ! $token ) {
            return;
        }

        // Validate token and get fresh user data.
        $api = new Bronnikov_API();
        $user_data = $api->validate_token( $token );

        if ( ! $user_data ) {
            return;
        }

        // Update WordPress user data.
        wp_update_user( array(
            'ID'         => $user->ID,
            'first_name' => sanitize_text_field( $user_data['first_name'] ?? '' ),
            'last_name'  => sanitize_text_field( $user_data['last_name'] ?? '' ),
        ) );

        // Update meta.
        update_user_meta( $user->ID, 'bronnikov_user_id', intval( $user_data['id'] ) );
        update_user_meta( $user->ID, 'bronnikov_classification', sanitize_text_field( $user_data['classification'] ) );
        update_user_meta( $user->ID, 'bronnikov_last_sync', time() );
    }

    /**
     * Get time since last sync for a user
     *
     * @param int $user_id WordPress user ID.
     * @return string Human-readable time difference.
     */
    public static function get_last_sync_time( $user_id ) {
        $last_sync = get_user_meta( $user_id, 'bronnikov_last_sync', true );

        if ( ! $last_sync ) {
            return __( 'Never synced', 'bronnikov-sso' );
        }

        return sprintf(
            /* translators: %s: time difference */
            __( '%s ago', 'bronnikov-sso' ),
            human_time_diff( $last_sync, time() )
        );
    }
}
