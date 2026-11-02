<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class ApiAuthenticationTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_register_with_unique_email_and_hashed_password(): void
    {
        $response = $this->postJson('/api/register', [
            'name' => 'Rani Rahmadani',
            'email' => 'rani@example.test',
            'password' => 'password123',
            'password_confirmation' => 'password123',
        ]);

        $response->assertCreated()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.user.email', 'rani@example.test');

        $user = User::query()->where('email', 'rani@example.test')->firstOrFail();
        $this->assertTrue(Hash::check('password123', $user->password));
        $this->assertNotSame('password123', $user->password);
    }

    public function test_registration_rejects_duplicate_email_and_invalid_fields(): void
    {
        User::factory()->create(['email' => 'rani@example.test']);

        $this->postJson('/api/register', [
            'name' => '',
            'email' => 'rani@example.test',
            'password' => 'short',
            'password_confirmation' => 'different',
        ])->assertUnprocessable()
          ->assertJsonPath('success', false)
          ->assertJsonStructure(['errors' => ['name', 'email', 'password']]);
    }

    public function test_registered_user_can_login_and_receive_sanctum_token(): void
    {
        User::factory()->create([
            'email' => 'rani@example.test',
            'password' => 'password123',
        ]);

        $response = $this->postJson('/api/login', [
            'email' => 'rani@example.test',
            'password' => 'password123',
        ]);

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.user.email', 'rani@example.test')
            ->assertJsonStructure(['data' => ['token', 'user']]);
    }

    public function test_login_rejects_invalid_password(): void
    {
        User::factory()->create([
            'email' => 'rani@example.test',
            'password' => 'password123',
        ]);

        $this->postJson('/api/login', [
            'email' => 'rani@example.test',
            'password' => 'incorrect123',
        ])->assertUnauthorized()
          ->assertJsonPath('success', false);
    }
}
