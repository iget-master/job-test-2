<?php

use Faker\Generator as Faker;
use App\Person;
use App\Contact;

/*
|--------------------------------------------------------------------------
| Model Factories
|--------------------------------------------------------------------------
|
| This directory should contain each of the model factory definitions for
| your application. Factories provide a convenient way to generate new
| model instances for testing / seeding your application's database.
|
*/

$factory->define(Person::class, function (Faker $faker) {
    $type = $attributes['type'] ?? $faker->randomElement(Person::AVAILABLE_TYPES);

    if ($type == Person::TYPE_PERSON) {
        $data = [
            'surname' => $faker->lastName,
            'gender' => $faker->randomElement(Person::AVAILABLE_GENDERS),
            'dob' => $faker->date(),
        ];
    } else {
        $data = [
            'company_name' => $faker->company,
        ];
    }

    return array_merge($data, [
        'type' => $type,
        'name' => $faker->name,
        'bank_data' => $faker->rgbColorAsArray,
        'creator_user_id' => $attributes['creator_user_id'] ?? factory(User::class)->create()->id,
    ]);
});

$factory->define(Contact::class, function (Faker $faker, $attributes) {
    $person_id = !array_key_exists('person_id', $attributes) ? factory(Contact::class)->create()->id : null;

    return [
        'person_id' => $person_id,
        'type' => $faker->word,
        'value' => $faker->numerify('#########')
    ];
});
